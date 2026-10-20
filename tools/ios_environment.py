#!/usr/bin/env python3
"""Select iOS connection presets without invoking Flutter, Xcode, or a network."""

import argparse
import base64
import binascii
from dataclasses import dataclass
import ipaddress
import json
import os
from pathlib import Path
import re
import stat
import tempfile


FILES = (
    "ios/Flutter/Generated.xcconfig",
    "ios/Flutter/flutter_export_environment.sh",
    "ios/Flutter/ephemeral/flutter_native_integration.env",
)
KEYS = ("APP_ENV", "USE_LOCAL_AUTH_API", "LOCAL_AUTH_API_HOST")
PRESETS = ("local", "test", "production")
LEGACY_PRESETS = {"test-server": "test", "ota-test": "test"}
SELECTION = "ios/Flutter/SelectedEnvironment.xcconfig"
SELECTION_HEADER = "// Selected by tools/ios_environment.py; rerun select if other defines change.\n"
LINE = re.compile(r'^(?:DART_DEFINES=([^\r\n]*)|export "DART_DEFINES=([^"\r\n]*)")\r?$', re.M)


class ConfigurationError(Exception):
    pass


def decode(encoded):
    """Retain unrelated encoded tokens verbatim; never expose their values."""
    result = []
    for token in encoded.split(",") if encoded else []:
        try:
            text = base64.b64decode(token, validate=True).decode("utf-8")
        except (ValueError, UnicodeError, binascii.Error):
            raise ConfigurationError("Invalid base64/UTF-8 in DART_DEFINES.") from None
        key, separator, value = text.partition("=")
        if not separator or not key:
            raise ConfigurationError("DART_DEFINES must contain key=value entries.")
        result.append((token, key, value if key in KEYS else None))
    return result


def targets(tokens):
    values = {}
    for _, key, value in tokens:
        if key in KEYS:
            if key in values:
                raise ConfigurationError(f"Duplicate managed define: {key}.")
            values[key] = value
    return values


def valid_host(host):
    try:
        ipaddress.IPv4Address(host)
        return True
    except ipaddress.AddressValueError:
        if re.fullmatch(r"[0-9.]+", host):
            return False
    return bool(re.fullmatch(
        r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
        r"(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*", host
    )) and len(host) <= 253


def normalize(preset):
    return LEGACY_PRESETS.get(preset, preset)


def desired(preset, host=None):
    preset = normalize(preset)
    if host is not None and preset != "local":
        raise ConfigurationError("--host is available only for local.")
    if preset == "local":
        if host is None or not valid_host(host):
            raise ConfigurationError("local requires --host with an IPv4 address or hostname, without a scheme, port, or path.")
        return {"APP_ENV": "local", "LOCAL_AUTH_API_HOST": host}
    if preset in ("test", "production"):
        return {"APP_ENV": preset}
    raise ConfigurationError("Unknown preset.")


def classify(values):
    if values in ({"APP_ENV": "test"}, {"APP_ENV": "ota-test"}):
        return "test"
    if values == {"APP_ENV": "production"}:
        return "production"
    if (set(values) == {"APP_ENV", "LOCAL_AUTH_API_HOST"}
            and values["APP_ENV"] == "local"
            and valid_host(values["LOCAL_AUTH_API_HOST"])):
        return "local"
    raise ConfigurationError("Select local, test, or production explicitly; managed defines are missing or conflicting.")


@dataclass
class GeneratedFile:
    path: Path
    original: bytes
    mode: int
    text: str
    start: int
    end: int
    tokens: list
    missing_line: bool = False

    def replacement(self, values):
        encoded = [token for token, key, _ in self.tokens if key not in KEYS]
        encoded += [base64.b64encode(f"{key}={value}".encode()).decode()
                    for key, value in values.items()]
        value = ",".join(encoded)
        if self.missing_line:
            newline = "\r\n" if "\r\n" in self.text else "\n"
            line = f'export "DART_DEFINES={value}"' if self.path.name == "flutter_export_environment.sh" else f"DART_DEFINES={value}"
            separator = "" if not self.text or self.text.endswith("\n") else newline
            return (self.text + separator + line + newline).encode()
        return (self.text[:self.start] + value + self.text[self.end:]).encode()


def read_all(root):
    configs = []
    for name in FILES:
        path = root / name
        if path.is_symlink() or not path.is_file():
            raise ConfigurationError(f"Required generated file is missing or is a symlink: {name}.")
        original = path.read_bytes()
        try:
            text = original.decode("utf-8")
        except UnicodeError:
            raise ConfigurationError(f"Generated file is not UTF-8: {name}.") from None
        matches = list(LINE.finditer(text))
        if not matches:
            if "DART_DEFINES" in text:
                raise ConfigurationError(f"Unsupported DART_DEFINES syntax: {name}.")
            configs.append(GeneratedFile(path, original, stat.S_IMODE(path.stat().st_mode),
                                         text, len(text), len(text), [], True))
            continue
        if len(matches) != 1:
            raise ConfigurationError(f"Expected at most one DART_DEFINES line: {name}.")
        match = matches[0]
        group = 1 if match.group(1) is not None else 2
        configs.append(GeneratedFile(path, original, stat.S_IMODE(path.stat().st_mode),
                                     text, match.start(group), match.end(group),
                                     decode(match.group(group))))
    return configs


def verify(configs, expected=None, inherited=None):
    selections = [targets(config.tokens) for config in configs]
    presets = [classify(values) for values in selections]
    if any(value != selections[0] for value in selections[1:]):
        raise ConfigurationError("The three generated configurations disagree; select a preset.")
    preset = presets[0]
    if expected is not None and preset != expected:
        raise ConfigurationError(f"Expected {expected}; selected {preset}. Run select {expected} first.")
    if inherited is not None and targets(decode(inherited)) != selections[0]:
        raise ConfigurationError("Inherited DART_DEFINES conflicts with the generated selection.")
    return {"preset": preset, "managed_defines": selections[0], "files_checked": len(configs)}


def unrelated(tokens):
    return [token for token, key, _ in tokens if key not in KEYS]


def selection_text(preset, tokens):
    encoded = ",".join(token for token, _, _ in tokens)
    if "//" in encoded:
        raise ConfigurationError("A define cannot be represented safely in the xcconfig; nothing was selected.")
    return SELECTION_HEADER + f"BS_IOS_PRESET={preset}\nDART_DEFINES={encoded}\n"


def read_selection(root):
    path = root / SELECTION
    if path.is_symlink():
        raise ConfigurationError("Persistent selection must not be a symlink.")
    if not path.exists():
        return None
    if not path.is_file():
        raise ConfigurationError("Persistent selection is not a regular file.")
    try:
        text = path.read_text(encoding="utf-8")
        match = re.fullmatch(re.escape(SELECTION_HEADER) +
                             r"BS_IOS_PRESET=(local|test|production|test-server|ota-test)\nDART_DEFINES=([^\r\n]*)\n", text)
        if match is None:
            raise ConfigurationError("Persistent selection is malformed; preserve it and inspect before proceeding.")
        tokens = decode(match.group(2))
        values = targets(tokens)
        # 旧設定はselectによる移行のためだけに読み取ります。
        legacy_local = (match.group(1) == "local"
                        and set(values) == {"USE_LOCAL_AUTH_API", "LOCAL_AUTH_API_HOST"}
                        and values["USE_LOCAL_AUTH_API"] == "true"
                        and valid_host(values["LOCAL_AUTH_API_HOST"]))
        legacy_test = match.group(1) == "test-server" and not values
        if not (legacy_local or legacy_test) and classify(values) != normalize(match.group(1)):
            raise ConfigurationError("Persistent preset and managed defines disagree.")
        if selection_text(match.group(1), tokens) != text:
            raise ConfigurationError("Persistent selection is not canonical.")
        return {"path": path, "preset": normalize(match.group(1)), "tokens": tokens}
    except UnicodeError:
        raise ConfigurationError("Persistent selection is not UTF-8.") from None


def verify_persistent(configs, selection, expected=None, inherited=None):
    values = targets(selection["tokens"])
    classify(values)  # 旧ローカル設定のままビルドして起動時に失敗することを防ぎます。
    for config in configs:
        if unrelated(config.tokens) != unrelated(selection["tokens"]):
            raise ConfigurationError("Other defines changed after selection; rerun select to preserve them before building.")
        current = targets(config.tokens)
        if current and current != values:
            raise ConfigurationError("Generated managed defines conflict with the persistent selection; rerun select.")
    if expected is not None and selection["preset"] != expected:
        raise ConfigurationError(f"Expected {expected}; selected {selection['preset']}.")
    if inherited is not None:
        tokens = decode(inherited)
        if [t for t, _, _ in tokens] != [t for t, _, _ in selection["tokens"]]:
            raise ConfigurationError("Resolved/inherited DART_DEFINES differs from the persistent selection; do not build.")
    return {"preset": selection["preset"], "managed_defines": values,
            "files_checked": len(configs), "persistent_selection": True,
            "other_defines_preserved": len(unrelated(selection["tokens"]))}


def atomic_write(path, content, mode):
    fd, temporary = tempfile.mkstemp(prefix=".ios-env-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(content)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def select(configs, values, dry_run=False, selection_root=None):
    planned = [(config.path, config.original, config.replacement(values), config.mode)
               for config in configs]
    if selection_root is not None:
        read_selection(selection_root)  # Reject unknown edits/symlinks before planning writes.
        if any(unrelated(config.tokens) != unrelated(configs[0].tokens) for config in configs[1:]):
            raise ConfigurationError("Generated files contain different other defines; inspect before selecting.")
        tokens = [entry for entry in configs[0].tokens if entry[1] not in KEYS]
        tokens += [(base64.b64encode(f"{key}={value}".encode()).decode(), key, value)
                   for key, value in values.items()]
        path = selection_root / SELECTION
        original = path.read_bytes() if path.exists() else None
        mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else configs[0].mode
        planned.append((path, original, selection_text(classify(values), tokens).encode(), mode))
    changed = [entry for entry in planned if entry[1] != entry[2]]

    def matches(path, original):
        return (not path.exists() and not path.is_symlink()) if original is None else (
            not path.is_symlink() and path.is_file() and path.read_bytes() == original)

    if not dry_run:
        if any(not matches(path, original) for path, original, _, _ in planned):
            raise ConfigurationError("Configuration changed concurrently; nothing was written.")
        applied = []
        try:
            for path, original, content, mode in changed:
                if not matches(path, original):
                    raise ConfigurationError("Configuration changed concurrently.")
                atomic_write(path, content, mode)
                applied.append((path, original, content, mode))
        except (OSError, ConfigurationError):
            incomplete = False
            for path, original, content, mode in reversed(applied):
                if matches(path, content):
                    if original is None:
                        path.unlink()  # Only a new selection file created by this transaction.
                    else:
                        atomic_write(path, original, mode)
                else:
                    incomplete = True
            if incomplete:
                raise ConfigurationError("Concurrent change prevented rollback; inspect status before proceeding.") from None
            raise ConfigurationError("Selection failed; applied changes were rolled back.") from None
    return {"preset": classify(values), "managed_defines": values, "dry_run": dry_run,
            "files_to_change" if dry_run else "files_changed": len(changed),
            "persistent_selection": selection_root is not None,
            "unrelated_define_counts_preserved": [len(unrelated(c.tokens)) for c in configs]}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    choose = commands.add_parser("select", help="update only the three managed define keys")
    choose.add_argument("preset", choices=(*PRESETS, *LEGACY_PRESETS))
    choose.add_argument("--host", help="required for local: reachable IPv4/hostname (reachability is not tested)")
    choose.add_argument("--dry-run", action="store_true")
    commands.add_parser("status", help="check effective selection in all three generated files")
    check = commands.add_parser("check", help="require a consistent preset")
    check.add_argument("--expect", choices=PRESETS)
    commands.add_parser("ota-check", help="compatibility alias for check --expect test; never builds")
    commands.add_parser("xcode-check", help="Flutter build-phase guard for the persistent selection; never builds")
    args = parser.parse_args(argv)
    try:
        root = Path(__file__).resolve().parents[1]
        selection = read_selection(root)
        configs = read_all(root)
        if args.command == "select":
            values = desired(args.preset, args.host)
            inherited = os.environ.get("DART_DEFINES")
            if inherited is not None and targets(decode(inherited)) != values:
                raise ConfigurationError("Inherited DART_DEFINES conflicts with the requested preset; unset it first.")
            if inherited is not None and unrelated(decode(inherited)) != unrelated(configs[0].tokens):
                raise ConfigurationError("Inherited other defines differ; unset DART_DEFINES before selection.")
            result = select(configs, values, args.dry_run, root)
            if not args.dry_run:
                result["files_checked"] = verify_persistent(read_all(root), read_selection(root),
                                                          normalize(args.preset))["files_checked"]
        else:
            expected = "test" if args.command == "ota-check" else getattr(args, "expect", None)
            if args.command == "ota-check" and selection is None:
                raise ConfigurationError("Select test before the OTA compatibility check.")
            inherited = os.environ.get("DART_DEFINES")
            if args.command == "xcode-check" and inherited is None:
                raise ConfigurationError("Xcode did not resolve DART_DEFINES; do not build.")
            result = (verify_persistent(configs, selection, expected, inherited) if selection is not None
                      else verify(configs, expected, inherited))
            values = result["managed_defines"]
            result["required_flutter_arguments"] = [
                f"--dart-define={key}={value}" for key, value in values.items()
            ]
        result["build_or_network_started"] = False
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (ConfigurationError, OSError) as error:
        # Do not print source lines, unrelated defines, or subprocess output.
        message = str(error) if isinstance(error, ConfigurationError) else "Cannot read or update generated configurations."
        print(json.dumps({"error": message}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
