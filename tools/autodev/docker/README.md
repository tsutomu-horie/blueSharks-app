# Android Runner imageの準備

以下をリポジトリrootから順番に実行する。SDK取得等のnetworkアクセスはimage準備時のみ使用し、実検証containerはDockerCheckにより `--network=none` で起動する。

## 1. Flutter 3.27.4 / JDK17ベース

```sh
docker build --pull=false \
  -f tools/autodev/docker/Dockerfile.base \
  -t bluesharks-autodev-flutter:3.27.4-jdk17-base \
  tools/autodev/docker
```

`Dockerfile.base` は `/private/tmp/bluesharks-docker-readiness/Dockerfile` の既存レシピを保存したもの。公開base `ghcr.io/cirruslabs/flutter:3.27.3` にOpenJDK17を導入し、公式Flutter repositoryのtag `3.27.4` を `/opt/bluesharks/flutter` へ新規cloneする。元baseのFlutter checkoutには依存せず、Android用Flutter artifactsも準備する。ローカルにbaseがない場合はDockerが取得する。

既存レシピのJava pathはLinux amd64向け。tagとapt packageは固定digest/versionではないため、再構築時のimage全体のバイト一致は保証しない。

## 2. Android SDK layer

```sh
docker build --pull=false \
  -f tools/autodev/docker/Dockerfile \
  -t bluesharks-autodev-flutter:3.27.4 \
  tools/autodev/docker
```

このlayerは `platforms;android-35`、`build-tools;33.0.1`、`build-tools;35.0.0`、`ndk;26.1.10909125` を追加し、必要なfilesの存在を確認する。33.0.1は実際のAndroid buildが要求したversionで、compileSdk35とNDKは既存Flutter 3.27.4の既定値に合わせる。製品のGradle設定や依存versionは変更しない。

更新するのは専用imageのtagのみ。Docker daemon、共有cache、元base imageを削除する操作は含まない。

## 検証

Runner configをメモリ上で `projects.app.check_backend = "docker"` と `sandbox.docker_image = "bluesharks-autodev-flutter:3.27.4"` に設定し、専用worktree・診断DBからAndroid debug buildを実行する。通過済みのpub/testの独立checkは繰り返さない。DockerCheckのoffline pub処理はLinux用package metadata生成のために実行される。

結果確認後は診断container・worktree・process・leaseをcleanupし、診断logs・DB・snapshotを保持する。
