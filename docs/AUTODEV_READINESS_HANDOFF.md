# 自律Runner始動準備の継続記録

更新: 2026-10-01。ユーザーは既知の障害を解消し、実行可能なチケットを整えてRunnerを開始することを許可済み。最新の追加指示により、全体管理はこのCodexスレッドへ移す。CLI管理AI・CLI作業ログAIは使わない。詳細は`AUTODEV_MANAGEMENT.md`。主力workerはGPT-6.1 Sol、CLI IntakeはLuna low、Astra最終エスカレーションはCodex上。

## 現在の作業

- Branch: `feature/autodev-runner-readiness`。未コミット。ユーザーの既存変更 `AGENTS.md` と `docs/admin_wireframe_implementation_gap_report.md` をPRへ混入させない。
- 新しいコード: `workspace.py`, `tool_evidence.py`, `service.py`, schema/test群。runtimeで通常ソースAgentのAppsを無効化、仕様確認専用AgentだけGoogle Drive connectorを有効化。作業ログのCLI Agentは起動しない。
- Google Drive CLI実接続は成功。`--ignore-user-config`でもremote installed pluginは使える。`codex mcp list`にDriveが無いことだけで利用不能と判断しない。
- Folder: `1aHGgByN73FyuxCEBPN-Ung9ZogIZv6C_`（ICC開発案件）。Spreadsheet: `17X-Ezvv2vNZHtK8LsKwcdFc72CspnhgortNS6g6QdWE`（ICCドリフト）。作業ログtab: `510981882` / 自律開発作業ログ。
- 接続証拠: MCP JSONLの実arguments/resultを受け取り、対象ID・tab metadata・recursive inventory・source content読取を検証。source本文は保存せずhashとmetadataのみ。作業ログは実get_spreadsheet_rangeのA:G readbackを照合して配信確定する。
- Sheets outboxはSQLite `workspace_deliveries`。Codex管理側がChrome拡張で書き、各event固有markerをG列へ記録して実読戻しを`worklog-confirm`で照合する。CLIは外部Sheetを書かない。失敗と未配信はstatusに保持し、`sync-logs --retry-failed`で明示再送できる。
- `management_requests`と`management.py`を追加。管理判断とmerge承認をこのCodexへ渡し、CLI Supervisor/Astra/作業ログAIは起動しない。5分heartbeatをこのスレッドへ新規登録済み（automationId: `bluesharks`, ACTIVE）。旧`bluesharks-5`は削除済み。管理・ログ・runtime関連テスト18件PASS後、待ち時間超過時の復帰と人間判断時の停止テストを追加。
- LegacyのCANCELLED状態を保存。`retriage-legacy`で最新仕様＋IntakeからApp/Server子Ticketを生成し、親のarchiveと依存先付け替えをStore transactionで行う。

## 準備できた環境

- Flutter 3.27.4 / Dart 3.6.2: `/Users/work/AgentWorkspace/toolchains/flutter-3.27.4`
- Android SDK: `/Users/work/AgentWorkspace/toolchains/android-sdk`
- JDK17: `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`
- Pub cache: `/Users/work/AgentWorkspace/cache/pub`
- Gradle seed: `/Users/work/AgentWorkspace/cache/gradle-seed`
- ユーザー提供Firebase入力: `/Users/work/Downloads/firebase_options.dart`, `/Users/work/Downloads/google-services.json`。Git ignore済みの隔離worktree内パスだけへcopyし、main・製品履歴へ追加しない。
- 元pubspec/lockのまま対象テスト5件PASS、Android debug host buildとGradle offline clean assembleDebug PASS。
- ADBホスト接続は成功。USBとWi-Fi表示は同じPixel5と思われるため、実端末台数をserial propertyで重複排除して確認する。2台必要な項目は保留としてログ赤字。
- 実運用向け設定案は `/private/tmp/bluesharks-readiness-config.toml`。現在の外部configはまだ更新していない。

## 残る実行順

### 2026-10-01 継続検証

- draft PR: https://github.com/tsutomu-horie/blueSharks-app/pull/40 。本体commit `d2a781b`。追加入力互換処理とDockerレシピは再レビュー済み（P1/P2追加なし）、対象25テストPASS。既存ユーザー変更2ファイルのSHA256は開始時と一致。
- 利用制限によるWorker/仕様確認の中断後、アプリの利用許可を再確認して担当と仕様フェーズを再開。成功済み接続フェーズは繰り返していない。

- 最新共通基盤検証: 143件PASS、1件skip。監査ログの構造化errorと作業ログcellのsecretマスクを修正し、別GPT-6.1 Sol reviewerでP1/P2追加なしを確認。
- 実CLI workspace-checkは成功。全13folder/156file候補を調査した結果、育成ゲーム全体には数値・日付・ミニゲーム条件の競合が残ったため全面verified=false。対象を状態復元・二重同期防止へ絞った再確認を実施中。未確定領域を推測でREADYにしない。
- Android Docker buildはJDK17問題解消後、android-35不足を検出。専用imageへplatform/build-tools/NDKを準備し再検証中。既存baseを保持する追加layerのみ。
- merge REJECT後は管理理由をDeveloperへ渡しQC/PR全体独立再レビュー/更新commit/新SHA承認へ戻す。NEEDS_HUMANはpauseを維持。

- 管理/サービス/Docker関連64件PASS。共通Orchestrator基盤変更のためtools/autodev全体136件を検証しPASS（1件skip、製品App全体回帰は実施していない）。
- Docker create前の永続intent記録に対応し、engineの孤立資源復旧でintentを確認・安全回収する経路を追加。既存3テストを2lease設計へ更新。
- JDK17版Docker imageのビルド完了を環境担当へ通知し、Android buildのみ再検証を依頼。独立敵対的レビューも再依頼中。これらの結果取得前にmerge/設定導入/Runner開始を行わない。
- 変更は未コミット。既存ユーザー変更2ファイル・製品ソースを保持。

1. 環境担当の本Runner macOS sandbox内Pub/Test/Build試験結果を取得し、必要な最小修正を行う。XDG_CONFIG_HOMEをTicket tempへ向ける修正済み。前日の/private/tmp設定は消えているので、設定をメモリで既存config+記載pathsから構築して検証中。
2. 敵対的Reviewerの再レビューを取得する。追加P1として親自身の前提依存を子へ継承・移行確定まで実行保留にする修正、採用仕様のタブ/範囲/slide位置を実読取証拠と対応させる修正が残る。service-startのidle登録済みjob再起動は修正済み。
3. 真のconnector write/readback・重複防止を実際の作業ログで検証する。Chrome拡張が操作可能なら優先し、ヘッドレスでは接続不能時にユーザー許可のDrive fallbackを使う。
4. ローカル対象検証・PR（日本語）・レビュー通過後merge・main pullを完了する。通常製品ソース変更は本準備PRに含めない。
5. SQLiteと既存configをバックアップして設定案を導入、`init`で加算migration、旧取消Ticketを維持し、高優先度の未完了Ticketを最新仕様でretriageする。
6. LaunchAgentをinstall/bootstrap、resumeし、実Agent起動とTicket処理が進むことをログで確認。停止指示時はpauseの安全境界を待ち、必要時service-stopする。

開始時点DBはpaused=true、旧9Ticket（BLOCKED4/NEEDS_DECISION1/NEEDS_SPECIFICATION4）、active lease0。作業準備中に勝手にREADYへ書き換えない。既存中止済みBS-001A/BS-ENV-001を復活させない。Firebase生成・広い機密ログ削除等の旧準備Ticketは以前の製品無変更方針と照合し、不要ならsupersededとして履歴を保持する。
