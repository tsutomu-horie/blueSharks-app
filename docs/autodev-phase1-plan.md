# BlueSharks 自律開発 Phase 1 計画

更新日: 2026-09-30

## 現況調査

1. **Repository**: AppのGitルートは `/Users/work/Documents/Git/blueSharks-app`。ServerのGitルートは `/Users/work/Documents/Git/blueSharks-server`、コード・Artisan作業ディレクトリは `bluesharks-develop/`。別Repository構成を維持する。
2. **Git状態**: この作業は `feature/headless-autonomous-development`。Appのルートには既存の `AGENTS.md` と `docs/admin_wireframe_implementation_gap_report.md` の未コミット変更があるため保持する。アプリ用作業worktreeにも未コミット変更があるため、Orchestratorの移行作業からは除外する。Server mainはclean。
3. **検証方法**: AppはFlutter/Dartのfocused testとanalyze、ServerはPHPUnit/Artisan testsとPHP lint。Mechanical checkはmacOS sandbox内でWorktree/Ticket専用一時領域だけ書込み可、外部通信不可。Android buildは事前に用意されたoffline Gradle cache seedがない場合、Ticket開始前にBLOCKEDとする。
4. **AGENTS.md**: App rootのユーザー変更を保持し、今回の実装では上書き・commitしない。
5. **Workspace**: `/Users/work/AgentWorkspace/{control,worktrees,snapshots,logs,artifacts,tmp}`。状態DBは `control/tickets.sqlite3`、Codex CLI runtime stateは専用の `control/codex-state`。ソースRepositoryから独立させる。
6. **Orchestrator**: Python 3.11標準ライブラリの決定論的CLI。AIはイベント単位でCodex CLIを起動し、定期ポーリングには使わない。
7. **Ticket DB**: `tickets`, `ticket_events`, `agent_runs`, `resource_leases`, `artifacts`。状態遷移・lease取得はSQLite transactionで直列化する。
8. **Ticket Intake**: 自然文をGPT-6 Luna / low / read-onlyで実行可能Ticket JSONへ変換し、Goal・Acceptance Criteria・Scope・禁止範囲・Testsを検証する。ChatGPT-auth Codex CLIではIntakeに`gpt-6-luna`、調査・実装・レビュー・Supervisorに`gpt-6.1-sol`を使用し、GPT-5.6を拒否する。Google Drive/Chrome bridgeが無いため、仕様依存Ticketは最新出典を本当に確認できない限り `NEEDS_SPECIFICATION` にする。
9. **状態遷移**: `NEW → TRIAGE → READY → RUNNING → READY_FOR_REVIEW → REVIEWING → READY_TO_MERGE → MERGED → CLEANUP → DONE`。失敗・判断待ち・範囲変更・キャンセルは明示的な例外状態にする。修復は最大2回。
10. **Worktree**: Ticketごとに `origin/main` をfetchしてから `bot/<ticket-id>` を作成。既存パス・ブランチ・作業中Ticketの衝突時は開始しない。各Phase後にGit identityと開始時base commitを確認し、Scope/Review/Commitを同じbase基準で照合。AppとServerを1 Ticketで同時変更せず、必要ならChangeset子Ticketへ分割する。
11. **Model Routing**: Lunaは分類・状態要約のみ。GPT-6.1 Solは調査・実装・Reviewer別セッション・Supervisorイベントを担当し、lowから開始する。難しい場合にmedium/highへ上げる。GPT-5.6系は明示的に拒否し、AstraはSupervisorがエスカレーションを決めた場合のみ使う。
12. **Resource Lease**: Orchestrator自身が起動したPID/Process Group、worktree、一時ディレクトリ、必要時ポートをTicket IDで記録する。キャンセルは当該Process Groupのみ停止する。
13. **Cleanup**: leaseを取得した資源だけ解放する。merge済みかつcleanなworktreeのみ自動削除し、差分が残るworktreeは保全して `BLOCKED` にする。
14. **Phase 1手順**: SQLite状態管理、自然文Intake、単一Ticket実行、worktree、Sol Developer、Mechanical QC、独立Sol Reviewer、reviewed SHA固定commit/PR/merge、監査イベント、cleanupを構築する。LaunchAgentはPR・DB移行・外部仕様/Sheet連携ゲートの確認後に有効化する。

## Phase 1 の停止条件

- GPT-5.6系モデルが選択された
- Ticketに必要なGoal/Acceptance Criteria/Scope/Testsがない
- 同じRepositoryに衝突するworktree、branch、leaseがある
- Scope外変更、秘密情報候補、禁止操作、API/DB/CI等のSupervisor判断対象を検出した
- Mechanical QCまたはReviewerがFAIL、あるいは修復回数を超えた
- 外部チェックが失敗・保留、GitHub権限不足、またはmerge条件を満たさない
- Cleanup対象にTicket外差分がある

## 起動前の未解決条件

- 旧9 Ticketは `BLOCKED:4`、`NEEDS_DECISION:1`、`NEEDS_SPECIFICATION:4`。現時点で開始可能Ticketは0件。
- Codex CLIからGoogle Drive/Chromeへ接続できず、Google Sheets「自律開発作業ログ」への自動同期も未実装。これらはユーザーの継続要件。
- Android build用offline Gradle cache seedが未設定。該当Ticketは安全に事前停止する。
- 旧Runnerを再起動せず、新Runnerもまだbootstrapしていない。
