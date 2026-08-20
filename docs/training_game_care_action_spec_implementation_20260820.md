# 育成ゲームのお世話アクション仕様 実装報告

確認日: 2026-08-20

## 参照したDrive資料

- [ICC_分岐シミュレータ_開発部向け補足_260814.md](https://drive.google.com/file/d/1ftucKyUC3yGtyj8sE_qIWnBfOU_nEITE/view)
- [ICC_育成ゲーム_分岐シミュレータ_260814.html](https://drive.google.com/file/d/1bwvUjKxwUSOk4pXwIBrBzcEnVPL4Bu4z/view)
- [ICCドリフト スプレッドシート](https://docs.google.com/spreadsheets/d/17X-Ezvv2vNZHtK8LsKwcdFc72CspnhgortNS6g6QdWE/edit)

## 確認結果

Drive資料では、ごはん・掃除・休養・筋トレに日次の実行回数上限は設けず、クールタイムを設ける仕様です。クールタイムの秒数は資料上「調整」とされており、正式値は未確定です。

また、清潔度が下がっていない状態で掃除した場合は、清潔度を上げず、行動回数だけを1回消費する空振り仕様です。

## 今回の実装

- ごはん、掃除、休養、筋トレにクールタイムを追加しました。
- クールタイムの暫定値は60秒です。正式値確定時はControllerの定数を変更してください。
- クールタイム中はボタンを無効化し、残り秒数を表示します。
- Controller側でも再チェックするため、画面遷移中の二重実行を防止します。
- クールタイムは行動完了時に開始し、アプリ内のローカル状態へ保存・復元します。
- 掃除時の清潔度が100以上の場合、清潔度とTECH傾向値を変更せず、行動回数とクールタイムだけを消費します。
- 日付変更時にクールタイムをリセットする処理は追加していません。日次回数制限ではなく、経過時間による待機だからです。
- ミニゲーム（タックル、パス＆ラン）には、資料記載どおり日次回数制限・クールタイムを追加していません。
- デバッグコマンドに行動別のクールタイム切り替えを追加しました。通常設定では、ごはん・掃除・休養・筋トレが有効、仕事・タックル・パス＆ランが無効です。

## 変更ファイル

- `lib/presentation/training_game/controllers/training_game.controller.dart`
- `lib/presentation/training_game/training_game.screen.dart`
