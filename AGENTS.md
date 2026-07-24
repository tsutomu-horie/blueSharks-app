# AGENTS.md

このファイルは、このリポジトリで作業するAIエージェント向けの共通ルールです。
リポジトリ内のすべてのファイルに適用します。配下のディレクトリに、より具体的な
`AGENTS.md` がある場合は、そのディレクトリ内に限り、より具体的な指示を優先します。

## 基本方針

- 回答、調査結果、変更内容の報告は原則として日本語で記述する。
- ファイル名や推測だけで判断せず、関連コード、呼び出し元、設定を確認してから作業する。
- 依頼された範囲だけを変更し、無関係なリファクタリングや整形を混在させない。
- ユーザーが作業中の変更を保持し、明示的な依頼なしに取り消し、上書き、削除をしない。
- 不明点があっても安全な読み取り調査は進める。結果が大きく変わる判断や、破壊的な操作が必要な場合は確認する。
- 秘密情報、アクセストークン、APIキー、証明書、個人情報をソース、テストデータ、ログへ追加しない。

## アプリケーション構成

本アプリはGetXを利用したFlutterアプリで、基本的な処理の流れは次のとおり。

```text
Screen -> GetX Controller -> Provider / Service -> Model / Storage
```

- `lib/main.dart`: Hive、Firebase、Analytics、SharedPreferences、ローカライズ、アプリ起動処理
- `lib/presentation/`: 機能単位の画面とGetX Controller
- `lib/infrastructure/navigation/`: ルート定義、`GetPage`、Controller Binding
- `lib/app/providers/`: GetConnectを利用したAPIアクセス
- `lib/app/services/`: 認証トークン、Analytics、通知などの共通サービス
- `lib/app/data/models/`: Freezed、JSON、Hiveで利用するモデル
- `lib/app/views/views/`: 複数機能で再利用するWidget
- `lib/utils/`: 定数、表示形式、設定、通知などの共通ユーティリティ
- `lib/generated/`: ローカライズ等の生成物

## 実装ルール

- 画面固有のUIは該当する `lib/presentation/<feature>/` 配下に置く。
- 複数機能で再利用するWidgetは `lib/app/views/views/` に置く。
- 画面のリアクティブな状態とユーザー操作は、原則として該当するGetX Controllerで管理する。
- HTTP通信はControllerやWidgetへ直接追加せず、`lib/app/providers/` のProviderへ置く。
- 認証、通知、Analyticsなど横断的な処理は、既存の `lib/app/services/` の責務を維持する。
- 新しい画面や遷移を追加するときは、画面だけでなく次を一式で確認する。
  - `lib/infrastructure/navigation/routes.dart`
  - `lib/infrastructure/navigation/navigation.dart`
  - `lib/infrastructure/navigation/bindings/controllers/`
- 既存機能を追跡するときは、Screen、Controller、ProviderまたはService、ModelまたはStorageの順に確認する。
- 既存の命名、ディレクトリ、GetXパターンを優先し、依頼なしに別アーキテクチャを導入しない。

## 生成ファイル

- `*.freezed.dart`、`*.g.dart`、`lib/generated/` 配下は原則として直接編集しない。
- Freezed、JSON、Hiveモデルの定義を変更した場合は、元のDartファイルを編集して生成処理を実行する。
- 通常の生成コマンドは次を使用する。

```sh
dart run build_runner build --delete-conflicting-outputs
```

- 生成結果に予想外の大規模差分が出た場合は、そのまま進めず原因を確認する。

## 維持するアプリ既定値

依頼に含まれない限り、次の既定値や既存方式を変更しない。

- 対応言語とフォールバックロケール: `ja_JP`
- ScreenUtilのデザインサイズ: `375 x 812`
- 認証トークンの保存: FlutterSecureStorage
- 軽量なフラグの保存: SharedPreferences
- キャッシュと永続モデル: Hive
- APIアクセス: GetConnect Provider
- Firebase Analytics、Messaging、Remote Configを利用する既存の起動フロー
- `lib/config.dart` による環境選択

## 事前確認が必要な変更

次の変更は影響範囲を説明し、ユーザーの明示的な依頼または承認を得てから実行する。

- Flutter、Dart、Gradle、CocoaPods、主要パッケージのバージョン更新
- パッケージの追加、削除、メジャーバージョン更新
- Firebaseプロジェクト、Bundle ID、Application ID、署名、証明書の変更
- local、dev、QAS、productionの接続先や既定環境の変更
- 認証方式、トークン保存、個人情報の保存方法の変更
- API仕様、モデル互換性、HiveのtypeIdまたは永続データ形式に影響する変更
- ルート名や既存画面URLの変更、機能横断の大規模リファクタリング
- ファイルの削除、生成物の大量更新、データを失う可能性があるコマンド
- リリース、ストア提出、外部サービスへの送信やデプロイ

## Firebase・ネイティブ機能

- Firebase設定ファイル、通知権限、Deep Link、バックグラウンド処理を変更するときは、Dart側だけでなくAndroidとiOSの設定も確認する。
- 通知、権限ダイアログ、WebView、Google Sign-Inなど、ネイティブ側に依存する機能はWidgetテストだけで完了としない。
- ログへFCMトークン、認証情報、会員情報などを出力しない。

## 検証

変更後は、影響範囲に応じて小さい確認から実行する。

```sh
dart format --output=none --set-exit-if-changed <変更したDartファイル>
flutter analyze
flutter test
```

- Dartファイルを変更した場合は、少なくとも変更ファイルのformat確認を行う。
- モデル注釈を変更した場合はコード生成後の差分と解析結果を確認する。
- 起動、Navigation、Firebase、権限、ネイティブ設定を変更した場合は、可能な範囲で対象プラットフォームのbuildまたはrunも確認する。
- リポジトリ全体の解析に既存の警告やエラーがある場合は、今回の変更による問題と既存問題を区別して報告する。
- テストを追加できない場合は、実施した代替確認と残るリスクを報告する。
- 可能な限りiOSまたはAndroidいずれかのエミュレータを使用し、実際に操作を行って確認をする。

## コードレビューと修正

- レビュー対象が指定されている場合は、そのファイル、機能、または差分を優先する。
- 対象が指定されていない場合は、`git status` と `git diff` を確認し、現在の作業差分を対象とする。
- レビュー前に既存のユーザー変更を把握し、依頼と無関係な変更を取り消したり上書きしたりしない。
- ファイル単体で判断せず、関連する呼び出し元、状態管理、データ取得、保存処理まで追跡する。
- 不具合、セキュリティ、データ損失、互換性、クラッシュにつながる問題を優先する。
- 問題を指摘するときは、対象箇所、発生条件、原因、影響を具体的に示す。
- 根拠をコードから確認できない懸念は、確定した問題と区別して報告する。
- 修正を依頼されている場合は、確認できた問題を依頼範囲内で修正する。指摘だけで完了しない。
- 修正にパッケージ更新、API仕様変更、永続データ形式変更などの事前承認事項が必要な場合は、勝手に実行せず影響と必要性を報告する。
- 修正後は影響範囲に応じた検証を実施し、今回の変更による問題と既存問題を区別する。
- レビュー結果は重要度の高い順に、対象ファイルと行、原因、影響、修正内容を報告する。
- 問題が見つからなかった場合も、確認した範囲と実施した検証を報告する。

## 完了報告

作業完了時は、簡潔に次を報告する。

- 何を変更したか
- 主要な変更ファイル
- 実行した検証と結果
- 未実施の検証、既知の制約、ユーザー判断が必要な事項

検証していない内容を、確認済みとして報告してはならない。
