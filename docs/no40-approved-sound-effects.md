# No.40 承認済み効果音

## 選定記録

Google Drive の「ICCドリフト」→「チケットリスト」→ TaskNo.40（42行目）にある既存の選定記録に従う。受球音は「バスケットでパスを受け取る」、パス失敗音は「しょげる」、両ミニゲームの結果画面音は「シーン切り替え1」。投球音、タックルの飛びかかり音、成功音、突破時音は選定・追加しない。TaskNo.66 の孵化SEには触れない。

## 素材と配置

素材は効果音ラボ公式ページから取得し、アプリ内の以下のパスに収録する。

| 用途 | 公式掲載名 | アプリ内パス | 公式掲載ページ |
| --- | --- | --- | --- |
| パス受球 | バスケットでパスを受け取る | `assets/audio/training_game/basket-path1.mp3` | [効果音ラボ「その他の効果音」](https://soundeffect-lab.info/sound/various/various3.html) |
| パス失敗 | しょげる | `assets/audio/training_game/cute-sad1.mp3` | [効果音ラボ「アニメ・演出」](https://soundeffect-lab.info/sound/anime/) |
| 結果画面 | シーン切り替え1 | `assets/audio/training_game/sceneswitch1.mp3` | [効果音ラボ「アニメ・演出」](https://soundeffect-lab.info/sound/anime/) |

各素材の取り込み時の SHA-256 は順に `2bf025debcf824540a828d7936c867503d3c715c1a72e8ad2d211816f89b59cc`、`ad4bea612eb57a5fa1be846a4c1bdcb9da27d1c61e512a9b851df40ab28df214`、`bccd846d58d03c110c8f9042d259d441bbc74e219dd77ecace6fb3b0e1598727`。

## 利用条件

[効果音ラボの利用規約](https://soundeffect-lab.info/agreement/)では、商用を含む利用が許可され、クレジット表記は不要。素材単体の再配布は禁止されている一方、アプリの操作音として組み込むことは再配布に該当しないと記載されている。[公式 FAQ](https://soundeffect-lab.info/faq/) もアプリの操作音としての組み込みを案内している。よって本アプリに効果音として同梱し、単体素材として配布しない。

## 再生箇所

- 受球: パスが仲間との衝突判定で成功確定した時。
- 失敗: 前方への不正なフリックを失敗判定した時、または仲間がパスを受け取れずボールロストが確定した時。
- 結果: パス＆ランまたはタックルの結果画面へ遷移した時。

再生は `TrainingGameSoundService` に集約し、音声プラグインの失敗はゲーム進行を止めない。成功・突破の再生経路は設けない。
