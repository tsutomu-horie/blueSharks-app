# BlueSharks Headless 自律開発 刷新引き継ぎ

更新日: 2026-09-30 (Asia/Tokyo)

## 目的と現在地

ユーザーが更新した `CODEX_HEADLESS_AUTONOMOUS_DEVELOPMENT.md` に合わせ、決定論的Orchestrator・SQLite Ticket DB・event-driven Codex起動をPhase 1として実装中。作業はこのリポジトリの `feature/headless-autonomous-development` ブランチで行う。

ユーザーは「刷新後に稼働」するよう明示済み。起動は許可されているが、以下の外部連携ゲートが未解決のため、現時点では新Runnerをbootstrapしていない。旧Runner/Supervisor/Debugger LaunchAgentはdisabledのまま。5分heartbeat `bluesharks-5` は削除済み。

## 必ず保持する既存状態

- Appルートのユーザー変更: `AGENTS.md`、`docs/admin_wireframe_implementation_gap_report.md`。今回の依頼範囲に必要なModel Routing/spec項目だけを `AGENTS.md` 末尾へ追記し、他の既存変更は保持する。
- App用作業worktreeの未コミット差分: `blueSharks-app-autodev-high-001`、`blueSharks-app-autodev-high-002`、ほか。移行・削除・reset・checkoutしない。
- Server mainと作業worktreeの状態、既存Markdown Ticket、既存ログは保持する。
- まだcommit、push、PR、mergeはしていない。

## 実装した制御系

主な新規ファイル:

- `tools/autodev/state.py`: SQLite状態、状態遷移、監査イベント、Agent run、Resource Lease
- `tools/autodev/intake.py`: 自然文Ticket Intake、入力とscope検証
- `tools/autodev/runtime.py`: Codex CLI起動、timeout、Process Group管理、秘密情報のログredaction
- `tools/autodev/git_manager.py`: Ticket worktree、scope/QC、snapshot、commit/PR/GitHub checks/merge、clean worktree cleanup
- `tools/autodev/engine.py`: triage、調査、Plan、Developer、Mechanical QC、独立Reviewer、修復、Supervisor/Astra escalation、PR処理
- `tools/autodev/decisions.py`: 人間判断が残るTicketの明示的な解決
- `tools/autodev/cli.py`: `タスク追加`、`緊急タスク追加`、`調査タスク追加`、追記、中止、resolve、status、run/pause/resume
- `tools/autodev/config.example.toml`: App/Server、model routing、GitHub、検証設定
- `tools/autodev/launchd/com.bluesharks.autodev.orchestrator.plist.template`: 新Runner用テンプレート。未導入・未起動
- `tools/autodev/tests/`: DB、Ticket Intake、Git scope/worktree、model routing、redaction、human resolutionのテスト
- `docs/autodev-phase1-plan.md`: 調査結果とPhase 1設計

Model routingはLunaをIntake/read-only/low、SolをInvestigator/Developer/Reviewer/Supervisor、AstraをSolが明示的にエスカレーションした時だけに設定。GPT-5.6系は設定検証と実行直前の両方で拒否する。Codex CLI用のChatGPT認証モデルIDは`gpt-6-sol`。古い設定値`gpt-6.1-sol`は読み込み時にCLI IDへ正規化する。

Server Gitルートは `/Users/work/Documents/Git/blueSharks-server`、コードルートは `bluesharks-develop/`。worktree Git操作は親Repository、AgentとPHPテストはsource directory内で行う。

## Workspaceと旧キュー

- Config: `/Users/work/.config/bluesharks-autodev/config.toml` をこの作業で新規作成。GitHub checksが空でもローカルQC+独立レビュー後にmergeできる設定。Branch protectionが人間レビューを要求する場合は回避せず保留する。
- Workspace: `/Users/work/AgentWorkspace/{control,worktrees,snapshots,logs,artifacts}` を作成。
- SQLite: `/Users/work/AgentWorkspace/control/tickets.sqlite3` を作成。
- 旧 `/Users/work/.autodev/blueSharks/tickets/*.md` の未完了9件を新DBへ保留Import済み。状態は `BLOCKED:4`、`NEEDS_DECISION:1`、`NEEDS_SPECIFICATION:4`。完了済み `BS-AUTO-000` はskip。Importerはworktreeを引き継いだり実行したりしない。
- pause flagはtrueに設定済み。実行・commit・mergeなし。
- Codex CLIは0.154.0から0.159.2へ更新済み。ChatGPT認証で`gpt-6-luna`と`gpt-6-sol`の読み取り専用スモークテストに成功。
- Config/DBはコード追加前後の簡易形式があり、最新DB列`specification_checked_at`、`base_commit`、`agent_runs.pid_start`を加算マイグレーションする必要がある。既存DBの安全停止状態を再確認してから`init`する。
- 実装にはfresh `origin/main` fetch、base commit基準のscope/review、worktree Git identity検査、.git pointer書込み禁止、独立review SHA固定merge、macOS test sandbox、Androidのoffline cache gateを追加済み。

## 直近の検証

- 最新Unit Test: 46件中45件PASS、1件は制限付き実行環境がnested macOS sandboxを拒否したためskip。別途権限付きsandbox確認は成功し、外部書込み・.git pointer変更・他プロセスsignalが拒否されることを確認。
- `compileall`、実config doctor（Codex CLI 0.159.2、App/Server repo、test sandbox）、plist lint、schema JSON parse、`git diff --check` は成功。
- Flutter/PHPの製品テストは、今回は自律開発制御系だけの変更なので未実施。
- CodexモデルAgentは起動していない。CLI login credential/API Keyを変更していない。

## 残りの作業

1. 直近の敵対的subagent reviewでP0/P1なしを確認済み。最終差分後にUnit Test/Doctorを再実行する。
2. App/Server双方の既存未コミット変更を保持し、今回の制御系ファイルだけを選択的にcommit・日本語PR化する。レビュー通過後にGitHub branch protection/checksを確認し、ユーザーが以前許可した範囲でmergeする。
3. 既存Ticket DBを読み取り確認し、加算migrationを実行する。旧9件は`BLOCKED:4`、`NEEDS_DECISION:1`、`NEEDS_SPECIFICATION:4`のため、仕様確認・判断なしに処理対象化しない。
4. LaunchAgentは、外部連携条件が解決するまで起動しない。

## 未完了・注意点

- Google Drive/Chrome拡張はCodex CLI runnerに接続されていない。仕様が必要なTicketは`NEEDS_SPECIFICATION`に停止する。
- Google Sheets「自律開発作業ログ」へのイベント同期も未実装。`codex mcp list`にGoogle Drive/Sheets接続はなく、過去の「完了ごとにSheet記録」要件を満たさない。
- Android debug build用の事前Gradle cache seedが未設定。該当Ticketは開始前に`BLOCKED`となり、ネットワークやユーザー共有Gradle cacheへフォールバックしない。
- 旧9 Ticketはすべて保留状態。Queueはactive Ticketを持たないため、Runnerを起動しても現行Queueで修正作業は始まらない。
- 旧サービスLaunchAgentは無効化済みで、新LaunchAgentはテンプレートだけ。Sheets/Drive接続とTicket queue準備の後にbootstrapする。
- BOTH/Changeset自動分割、並列Agent、外部Sheet同期、長期token-exhaustion retryはPhase 2/3の残課題。
