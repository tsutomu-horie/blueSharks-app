# BlueSharks 自律開発 Orchestrator

Python 3.11標準ライブラリとSQLiteでTicket・Agent run・Resource Leaseを管理する、イベント駆動のPhase 1実装です。旧Runner/Supervisor/Debuggerは自動で起動・変更しません。

## Model Routing

- Ticket Intake: `gpt-6-luna / low / read-only`
- Investigator・Developer・Reviewer: `gpt-6.1-sol`（GPT-6.1 Sol）。通常low、修復medium
- 管理・最終merge判断: このCodexスレッド。SQLiteの管理要求に根拠付きで回答し、CLI Supervisorは起動しない
- 管理レビュー: CodexサブエージェントのGPT-6.1 Sol。Astraは解決不能時だけCodex上で使用
- GPT-5.6系は設定段階と実行直前の両方で拒否
- GPT-6.1 SolはCodex CLI 0.159.2以上（本環境での最小確認バージョン）で`gpt-6.1-sol`を直接指定する。利用可否はChatGPTアカウント／Workspaceのモデル提供状況にも従う。

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

通常の不具合・新規機能はTicket IntakeがGoal・Acceptance Criteria・Scope・禁止範囲・priority・risk・testsを作成します。Google Drive「ICC開発案件」の最新資料を実取得して出典・確認時刻を残し、不足が残るTicketは `NEEDS_SPECIFICATION`、P0候補や高リスクはCodex管理の判断まで実行しません。P2は自動実行せずBacklogへ置きます。調査Ticketはread-onlyです。

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

`NEEDS_SPECIFICATION`、`NEEDS_DECISION`、`BLOCKED`、`REPLAN`は `resolve` で明示的に修正範囲・Acceptance Criteria・テスト・最新仕様出典を補ってから再開できます。GitHub PRが既にあるTicketを通常の`resolve`で再利用することはできません。merge管理REJECTだけは、同じ範囲の修正・QC・独立再レビューを経て既存PRへ更新commitを追加し、最新SHAへの新しい承認を要求します。追加要件は新しいTicketへ分けます。

LaunchAgentのテンプレートは `launchd/com.bluesharks.autodev.orchestrator.plist.template` にあります。明示的にサービス導入・起動するまでは自動起動しません。サービス停止時もqueue state・worktree・logは保持します。

## 実行ゲート

1. Ticket DBからP0/P1を優先順で1件claim。依存TicketがDONEでなければ待機。
2. `origin/main`から `bot/<ticket-id>` と専用Worktreeを作成。
3. Sol Investigatorがread-onlyで調査。ICC仕様を参照できる場合は最新資料と確認時刻を記録し、必要時だけSol Planner。
4. Sol DeveloperがTicket scope内で編集。
5. OrchestratorがScope、禁止範囲、diff check、秘密情報パターン、サイズを検査し、Ticketに登録されたproject設定済みchecksのみ実行。
   Mechanical checkは設定したmacOS sandboxまたはApp専用Dockerで実行し、書込みをTicket専用Worktreeと一時領域に制限、ネットワークと秘密情報環境変数を遮断。Dockerは`--network=none`でゲスト内loopbackのみ使用し、host HOME・socket・共有cacheをmountしない。backendを使えない場合は検証を実行せず停止。
   Android debug buildは、隔離されたオフラインGradle cache seed (`sandbox.gradle_cache_seed`) が用意されている場合だけ実行。未設定・不完全ならネットワーク取得へ切り替えずTicketをBLOCKEDにする。
6. Mechanical QCが全件PASSした場合に、別Sol Reviewerを起動。
7. P0/P1レビュー指摘は最大2回修復。上限後はCodex管理へREPLAN判断を要求し、無制限の自動ループを止める。
8. QCとReviewerがPASSした場合だけOrchestratorがcommit・push・日本語PRを作成。レビュー済SHA・最新仕様・実テストをCodex管理が確認して承認し、GitHub checksが成功し、PRがmerge可能な状態の場合だけmerge。
9. GitHubでMERGEDを確認後、cleanなworktreeのみ削除。差分や未merge commitのあるworktreeは保持してTicketを停止。

秘密情報、本番DB/deploy、Signing、Store申請、データ消失、Dependency/API/DB/CIの変更は自動承認しません。Ticket・Agent出力はuntrusted dataとして扱います。AgentのJSONL command outputは監査ログに保存せず、最終構造化結果もredactします。

状態復元Ticketの`flutter_analyze_training_restore`は許可3 Dartファイルに対象を限定し、infoを非致命、warning/errorを致命として解析する。全体`flutter_analyze`の設定値と閾値は変更しない。既存repository-wide info/warningとTicket起因の検出を混同しないための専用checkである。

## データ配置

管理要求は`manage-list`/`manage-show`、作業ログ未配信は`worklog-list`で確認する。Sheets追記はこのCodexからChrome拡張優先で行い、実読戻しを`worklog-confirm`へ渡す。詳細は`docs/AUTODEV_MANAGEMENT.md`。CLIはSheets編集AIを呼ばない。

Google Drive connectorが小さいMarkdown等の本文をlegacy `b64_string`で返す環境では、`google_workspace.text_base64_compatibility=true`を明示して互換読取を使う。対象はID一致・上限付きUTF-8テキストのみで、制御文字・credential名・private key・binaryを拒否する。仕様Agentは復号本文を実際に読み、監査はhashだけを保持する。URIだけでは仕様確認済みとしない。

Docker createがtimeout等で不確定となった場合は、単発の不存在確認でintentを解放せず、一時領域・repository leaseを保持する。後続復旧で実containerを確認して回収するまで、自動削除・完了扱いにしない。

- SQLite: `AgentWorkspace/control/tickets.sqlite3`
- Worktrees: `AgentWorkspace/worktrees/<project>/<ticket-id>`
- Snapshots: `AgentWorkspace/snapshots/<ticket-id>`
- Logs: `AgentWorkspace/logs/<ticket-id>`
- Artifacts: `AgentWorkspace/artifacts/<ticket-id>`

## 検証

```sh
python3 -m unittest discover -s tools/autodev/tests -v
```
