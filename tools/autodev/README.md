# BlueSharks 自律開発 Orchestrator

Python 3.11標準ライブラリとSQLiteでTicket・Agent run・Resource Leaseを管理する、イベント駆動のPhase 1実装です。旧Runner/Supervisor/Debuggerは自動で起動・変更しません。

## Model Routing

- Ticket Intake: `gpt-6-luna / low / read-only`
- Investigator・Developer・Reviewer: `gpt-6-sol`（GPT-6 Sol）。通常low、修復medium
- Supervisor: `gpt-6-sol / medium`。Ticket判断・範囲変更・修復上限でのみ起動
- Astra: Supervisorが明示的に最終エスカレーションを要求した場合のみ
- GPT-5.6系は設定段階と実行直前の両方で拒否
- ChatGPT認証でGPT-6モデルを選ぶにはCodex CLI 0.156.0以降が必要。旧設定のAPI向け`gpt-6.1-sol`はCLI用`gpt-6-sol`へ読み込み時に正規化する。

Orchestrator自体はAIを使いません。空キュー時はSQLite状態だけを確認し、AIへ状態照会を行いません。

## 初期設定

```sh
python3 -m tools.autodev.cli install-config
```

生成された `~/.config/bluesharks-autodev/config.toml` を確認し、Repository、`/Users/work/AgentWorkspace`、Flutter/PHP検証コマンドを調整します。既存設定があれば上書きしません。

```sh
python3 -m tools.autodev.cli init
python3 -m tools.autodev.cli doctor
python3 -m tools.autodev.cli import-legacy /Users/work/.autodev/blueSharks/tickets
```

DBやWorkspaceは `init` 実行時にだけ生成します。Repository内にTicket DBを置きません。旧Markdown Ticketは既存worktreeを上書きせず、scope/testsが明確でないものは `NEEDS_SPECIFICATION`、作業中・親Gate待ちは `NEEDS_DECISION`、旧Blockは `BLOCKED` として保留Importします。`DONE`は既定でskipします。

## Ticket投入コマンド

```sh
python3 -m tools.autodev.cli タスク追加 --request '不具合や機能の自然文'
python3 -m tools.autodev.cli 緊急タスク追加 --request '緊急の自然文'
python3 -m tools.autodev.cli 調査タスク追加 --request '調査したい内容'
python3 -m tools.autodev.cli append BS-YYYYMMDD-ABC123 --text '追記内容'
python3 -m tools.autodev.cli cancel BS-YYYYMMDD-ABC123
python3 -m tools.autodev.cli resolve BS-YYYYMMDD-ABC123 --action approve --note '仕様と追加Scopeを確認' --goal '...' --criterion '...' --scope 'lib/feature/**' --test flutter_test --target test/feature/example_test.dart --spec-source 'Drive資料名/URL' --spec-checked-at '2026-09-30 09:00 JST'
```

通常の不具合・新規機能はTicket IntakeがGoal・Acceptance Criteria・Scope・禁止範囲・priority・risk・testsを作成します。不足が残るTicketは `NEEDS_SPECIFICATION`、P0候補や高リスクはSol Supervisorの判断まで実行しません。P2は自動実行せずBacklogへ置きます。調査Ticketはread-onlyです。

## 実行と停止

```sh
python3 -m tools.autodev.cli run --once
python3 -m tools.autodev.cli run --continuous
python3 -m tools.autodev.cli pause
python3 -m tools.autodev.cli resume
python3 -m tools.autodev.cli status
python3 -m tools.autodev.cli show BS-YYYYMMDD-ABC123
```

`pause` は実行中Ticketを安全な完了境界まで進めて、新しいTicket取得を止めます。`cancel` は対象Ticketだけを次のphase境界で中断します。どちらも自分のAgent Process Group以外を停止しません。

`NEEDS_SPECIFICATION`、`NEEDS_DECISION`、`BLOCKED`、`REPLAN`は `resolve` で明示的に修正範囲・Acceptance Criteria・テスト・最新仕様出典を補ってから再開できます。GitHub PRが既にあるTicketは同じブランチで再開できず、追加要件は新しいTicketへ分けます。

LaunchAgentのテンプレートは `launchd/com.bluesharks.autodev.orchestrator.plist.template` にあります。明示的にサービス導入・起動するまでは自動起動しません。サービス停止時もqueue state・worktree・logは保持します。

## 実行ゲート

1. Ticket DBからP0/P1を優先順で1件claim。依存TicketがDONEでなければ待機。
2. `origin/main`から `bot/<ticket-id>` と専用Worktreeを作成。
3. Sol Investigatorがread-onlyで調査。ICC仕様を参照できる場合は最新資料と確認時刻を記録し、必要時だけSol Planner。
4. Sol DeveloperがTicket scope内で編集。
5. OrchestratorがScope、禁止範囲、diff check、秘密情報パターン、サイズを検査し、Ticketに登録されたproject設定済みchecksのみ実行。
   Mechanical check子プロセスはmacOS sandboxで実行し、書込みをTicket専用Worktreeと一時領域に制限、ネットワークと秘密情報環境変数を遮断。sandboxを使えない場合は検証を実行せず停止。
   Android debug buildは、隔離されたオフラインGradle cache seed (`sandbox.gradle_cache_seed`) が用意されている場合だけ実行。未設定・不完全ならネットワーク取得へ切り替えずTicketをBLOCKEDにする。
6. Mechanical QCが全件PASSした場合に、別Sol Reviewerを起動。
7. P0/P1レビュー指摘は最大2回修復。上限後はSol SupervisorでREPLANし、自動ループを止める。
8. QCとReviewerがPASSした場合だけOrchestratorがcommit・push・日本語PRを作成。GitHub checksが成功し、PRがmerge可能な状態の場合だけmerge。
9. GitHubでMERGEDを確認後、cleanなworktreeのみ削除。差分や未merge commitのあるworktreeは保持してTicketを停止。

秘密情報、本番DB/deploy、Signing、Store申請、データ消失、Dependency/API/DB/CIの変更は自動承認しません。Ticket・Agent出力はuntrusted dataとして扱います。AgentのJSONL command outputは監査ログに保存せず、最終構造化結果もredactします。

## データ配置

- SQLite: `AgentWorkspace/control/tickets.sqlite3`
- Worktrees: `AgentWorkspace/worktrees/<project>/<ticket-id>`
- Snapshots: `AgentWorkspace/snapshots/<ticket-id>`
- Logs: `AgentWorkspace/logs/<ticket-id>`
- Artifacts: `AgentWorkspace/artifacts/<ticket-id>`

## 検証

```sh
python3 -m unittest discover -s tools/autodev/tests -v
```
