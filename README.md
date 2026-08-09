# fetokku

## 目次

- [fetokku](#fetokku)
  - [目次](#目次)
  - [サービス概要](#サービス概要)
  - [デモ動画](#デモ動画)
    - [友達追加](#友達追加)
    - [出題～回答～正誤判定～解説リンク](#出題回答正誤判定解説リンク)
    - [設定変更](#設定変更)
  - [サービスURL](#サービスurl)
  - [開発の背景](#開発の背景)
  - [主な機能](#主な機能)
  - [使用技術](#使用技術)
  - [技術選定理由](#技術選定理由)
    - [【フレームワーク】Ruby on Rails 7.2.3](#フレームワークruby-on-rails-723)
    - [【開発環境】Docker](#開発環境docker)
    - [【データベース】Neon（PostgreSQL）](#データベースneonpostgresql)
    - [【非同期処理】Solid Queue](#非同期処理solid-queue)
    - [【コア技術】LINE Messaging API / LIFF](#コア技術line-messaging-api--liff)
    - [【デプロイ先】Render](#デプロイ先render)
  - [開発環境構築方法](#開発環境構築方法)
    - [環境変数の設定](#環境変数の設定)
    - [スマートフォンからローカル環境を確認する場合](#スマートフォンからローカル環境を確認する場合)
    - [データベースのリセット](#データベースのリセット)
  - [工夫したポイント](#工夫したポイント)
    - [SM-2アルゴリズムと配信頻度設定を組み合わせた「自己連鎖ジョブ」](#sm-2アルゴリズムと配信頻度設定を組み合わせた自己連鎖ジョブ)
    - [LINE IDTokenのサーバーサイド検証](#line-idtokenのサーバーサイド検証)
  - [ER図](#er図)
  - [画面遷移図](#画面遷移図)

## サービス概要

基本情報技術者試験（科目A）の過去問を、忘却曲線に基づいた最適なタイミングでLINEに自動送信する学習サポートアプリです。「勉強を始めるのが億劫」という心理的ハードルを、日常的に開いているLINEへのプッシュ通知で解消し、意志の力に頼らない学習習慣の定着を支援します。

## デモ動画

### 友達追加

https://github.com/user-attachments/assets/e10cda33-b9aa-43f9-ae9f-de71b771b32f

### 出題～回答～正誤判定～解説リンク

https://github.com/user-attachments/assets/55fa4840-f4ac-4908-99c1-5615857812f1

### 設定変更

https://github.com/user-attachments/assets/e14b541c-c8e6-41c9-a0ce-727a45fd9543


## サービスURL

https://fetokku.com

LINEで [友だち追加](https://lin.ee/nLa70jJ) すると、すぐにご利用いただけます。

## 開発の背景

Ruby on Railsを学習する中で、コードの書き方はわかっても土台となるコンピュータサイエンスの基礎知識が抜けていると感じ、基本情報技術者試験の学習を始めました。しかし在職中で疲労が溜まった状態では、「わざわざ学習アプリを開く」という最初の一歩が重く、学習が続かない日々が続きました。

一方で、SNSの通知には無意識に指が動いてしまう自分に気づき、「自ら開くのは億劫でも、届いた通知には反応できる」という性質を逆手に取れないかと考え、本アプリを開発しました。

同じように「勉強を続けたいのに続けられない」社会人をターゲットに、以下の課題を解決することを目指しています。

- 勉強開始のスイッチが入らず、ついSNSなどを優先してしまう
- 復習すべきタイミングを忘れてしまう
- 隙間時間があっても「何を復習すべきか」を判断するのが面倒で、結局手をつけない

これらに対し、SM-2（忘却曲線）アルゴリズムで復習タイミングを自動計算し、LINEのプッシュ通知でユーザー側の判断・管理コストをゼロに近づけることで、「ただ解くこと」だけに集中できる環境を提供します。

## 主な機能

| 機能 | 概要 |
| --- | --- |
| LINE登録導線（LP・QRコード） | LINE未登録のユーザーでも、Webからすぐに友だち追加できる導線を提供 |
| 自動出題 | SM-2アルゴリズムに基づき、ユーザーごとに最適なタイミングで問題をLINEへプッシュ配信 |
| 即時正誤判定 | Flex Messageの選択肢をタップするだけで、その場で正誤判定を表示 |
| 学習履歴（LIFF） | GitHub風ヒートマップ・Chart.jsによる習熟度トレンドグラフで学習状況を可視化 |
| 配信設定（LIFF） | 配信頻度・時間帯をユーザー自身でカスタマイズ可能 |
| 学習履歴のSNS共有 | 学習記録をXへワンタップで共有可能（OGP画像を動的生成） |

## 使用技術

| カテゴリ | 技術 |
| --- | --- |
| フレームワーク | Ruby on Rails 7.2.3 |
| 開発環境 | Docker |
| データベース | Neon（PostgreSQL） |
| 非同期処理 | Solid Queue |
| コア技術 | LINE Messaging API / LIFF |
| デプロイ先 | Render |
| バージョン管理 | GitHub（Git-flow / Issue駆動開発） |

## 技術選定理由

本アプリの価値は「ユーザーが能動的にアプリを開かなくても、忘却曲線上の最適なタイミングで問題が届く」という体験にあります。この体験を実現する観点から、各技術を選定しました。

### 【フレームワーク】Ruby on Rails 7.2.3

Webhook受信、LIFF画面の提供、SM-2アルゴリズムに基づく非同期ジョブ処理という、性質の異なる3つの処理を1つのアプリケーションで一貫して実装する必要がありました。Railsは「設定より規約」の思想により、これらをMVCの型に沿って迷いなく実装でき、個人開発の限られた期間内で機能を完成させることができました。また、スクールのカリキュラムで学習していたため、新しい言語・フレームワークの学習コストをかけず、アルゴリズムやアーキテクチャ設計といった本質的な部分に開発時間を充てられた点も理由の一つです。

### 【開発環境】Docker

Web（Rails）・Worker（Solid Queue）・DB（本番用・テスト用）という複数のプロセスを組み合わせて動かす構成のため、ローカル環境ごとの差異でジョブが正しく動かない、といった事態を避ける必要がありました。Dockerでコンテナ単位に環境を分離・統一することで、環境依存の不具合を防ぎ、アプリ本来のロジック実装に集中できました。

### 【データベース】Neon（PostgreSQL）

LINE Botは、一般的なWebアプリのように「ユーザーが常時アクセスし続ける」のではなく、SM-2アルゴリズムによる配信タイミングやLINEからのWebhookイベント（即時出題・回答・LIFF画面の利用等）を起点とした、散発的なアクセスパターンになります。Neonはストレージとコンピューティングが分離されたサーバーレス構成を持ち、PostgreSQL互換のためRailsとの親和性も高く、こうした常時高負荷ではないアプリケーションの特性と相性が良いと考え採用しました。

また、RenderにもマネージドPostgreSQLはありますが、Neonはブランチ機能により本番相当のDBを数秒でコピーできる点が明確な差別化ポイントです。develop運用でのPRプレビュー環境において、本番DBに影響を与えずDB依存の機能を検証できる構成を将来的に取り入れやすい点も選定理由の一つです。無料プランでスモールスタートできる点も、個人開発のポートフォリオという規模感に合っていました。

### 【非同期処理】Solid Queue

本アプリの核であるSM-2（忘却曲線）アルゴリズムは、「ユーザーごとに異なる復習タイミングで問題を届ける」ことが価値の前提になります。Solid QueueはActiveJobの`wait_until`機能により、次回配信時刻をジョブ自身が計算し、自らを再スケジュールする「自己連鎖」の仕組みをRails標準機能の範囲で実現できました。

非同期ジョブ処理の選択肢としてRedis + Sidekiqも検討しましたが、Sidekiqの強みはジョブ数・並列実行数が多い大規模環境でのスループットや、Redisという高速なインメモリストアを活かした処理性能にあります。本アプリは個人開発規模であり、その強みを十分に活かせる段階ではないと判断しました。Solid QueueはPostgreSQL（既存のDB）上で完結するため、Redisという新たなミドルウェアを学習・導入することなく、配信スケジューリングという中核機能に集中して取り組めた点が最大の理由です。今後ユーザー数・ジョブ量が大きく増加する局面では、Redis + Sidekiqへの移行も選択肢に入ると考えています。

### 【コア技術】LINE Messaging API / LIFF

本アプリの価値は「ユーザーが能動的にアプリを開かなくても、忘却曲線上の最適なタイミングで問題が届く」という体験にあります。LINE Messaging APIのプッシュメッセージ機能により、SM-2アルゴリズムが計算した配信タイミングをユーザー側の行動に頼らず能動的に届けることができ、Flex Messageで選択肢をボタン化することで「通知→タップ→即時正誤判定」をLINEのトーク画面内だけで完結させています。一方、学習履歴のヒートマップや配信頻度設定など情報量の多い画面はLIFFで補完し、LINEという「日常的に開いているプラットフォーム」から離脱させずに機能を提供できる点も、継続利用を狙う本アプリの設計思想と合致していました。

### 【デプロイ先】Render

Solid QueueによるWorkerプロセスと、Webhookを受けるWebサービスを分離して常時稼働させる必要がありました。RenderはDockerベースでWeb・Workerそれぞれのサービスを個別にデプロイ・管理でき、インフラ構築の負担を抑えながら、配信スケジューリングというアプリ本来の機能開発に集中できる点から採用しました。

デプロイ先はHeroku・Fly.io・Railwayとも比較検討しました。Herokuは無料プランが既に終了しており価格面での優位性が薄いこと、Fly.ioは複数大陸にまたがるグローバル分散に強みがあるものの本アプリは国内ユーザーを想定しているため恩恵が小さいこと、Railwayは使用量ベース課金で個人開発規模ではコスト面に分があるものの、マネージドPostgreSQLの機能（自動バックアップ等）の充実度ではRenderに一歩譲ることから、最終的にRenderを選定しました。


## 開発環境構築方法

本アプリはDockerで開発環境を統一しており、`docker compose up` 1つで以下のサービスがまとめて起動します。

| サービス | 役割 |
| --- | --- |
| `web` | Railsサーバー（`bin/dev` により Rails / JSビルド / CSSビルド / Solid Queueをまとめて起動） |
| `db` | 開発用PostgreSQLデータベース（コンテナ内で完結） |
| `test` | テスト実行専用コンテナ（`RAILS_ENV: test`で分離） |

Solid Queue（非同期ジョブ）は独立したコンテナではなく、`web` サービス内で [`Procfile.dev`](./Procfile.dev) を通じて他のプロセスと合わせて起動します。

```
web:    Railsサーバー（bin/rails server）
js:     JSアセットのビルド・監視（yarn build --watch）
css:    SCSSのビルド・監視（yarn watch:css）
worker: Solid Queueワーカー
```

### 環境変数の設定

`.env.sample` をコピーして `.env` を作成し、各値を設定してください。

\`\`\`bash
cp .env.sample .env
\`\`\`

| 変数名 | 取得方法 |
| --- | --- |
| `LINE_CHANNEL_SECRET` / `LINE_CHANNEL_TOKEN` | LINE Developers Console の Messaging APIチャネル |
| `LIFF_CHANNEL_ID` | LINE Developers Console の LIFFタブ |
| `LIFF_ID_HISTORY` / `LIFF_ID_SETTINGS` | 同上（学習履歴用・配信設定用それぞれのLIFF ID） |


### スマートフォンからローカル環境を確認する場合

同一Wi-Fi内の実機からローカルサーバーへアクセスしたい場合、WSL2環境ではWindows側でのポート転送（`netsh interface portproxy`）とRailsの`config.hosts`設定が別途必要です。

### データベースのリセット

```bash
docker compose exec web bundle exec rails db:reset
```

## 工夫したポイント

### SM-2アルゴリズムと配信頻度設定を組み合わせた「自己連鎖ジョブ」

本アプリでは、「いつ届けるか」と「何を届けるか」を別々の仕組みとして設計し、それぞれをジョブの中で組み合わせています。

**いつ届けるか（自己連鎖ジョブによる配信スケジューリング）**

ユーザーが`delivery_settings`で設定した配信頻度・時刻をもとに、`DeliveryTimeCalculator`が次回配信時刻を算出します。`DeliverQuestionJob`は配信完了のたびにこの時刻を再計算し、`set(wait_until:)`で**自分自身を再スケジュールする**「自己連鎖」方式を採用しました。これにより、全ユーザーを定期的にスキャンするポーリング処理を持たずに、ユーザーごとに異なる生活スタイル（起床・通勤時間帯など）に合わせた配信タイミングを個別管理できます。

```ruby
# app/jobs/deliver_question_job.rb
def perform(user_id)
  # ...出題・配信処理...

  next_time = DeliveryTimeCalculator.call(setting)
  if next_time
    DeliverQuestionJob.set(wait_until: next_time).perform_later(user.id)
  end
end
```

**何を届けるか（SM-2に基づく問題選択）**

配信のたびに、70%の確率で「復習問題」を、残り30%の確率で「未回答の新問題」をランダムに選択します。復習問題は、SM-2アルゴリズムが計算した`next_review_at`が現在時刻以前のもの、または`next_review_at`が未計算（＝初回回答のみでまだ間隔反復が始まっていない）問題を対象に、最も緊急度の高いものから順に1件選びます。

```ruby
# app/models/answer.rb
scope :due_for_review, -> { where("next_review_at <= ? OR next_review_at IS NULL", Time.current) }
scope :by_next_review, -> { order(:next_review_at) }
```

```ruby
# app/jobs/deliver_question_job.rb
REVIEW_RATIO = 0.7  # 復習70%・新問題30%

def select_question(user)
  if rand < REVIEW_RATIO
    review_question = Answer.where(user_id: user.id)
                            .due_for_review
                            .by_next_review
                            .includes(:question)
                            .first&.question
    return review_question if review_question
  end

  answered_ids = Answer.where(user_id: user.id).pluck(:question_id)
  Question.where.not(id: answered_ids).order("RANDOM()").first
end
```

復習を100%にしなかったのは、復習対象がない（またはまだ少ない）学習初期のユーザーに問題が届かなくなる状態を避けるためです。SM-2は「既知の問題をいつ思い出すか」の最適化には強い一方、新規知識のインプットについては関与しないため、新問題枠を独立して確保することで、学習範囲が復習対象に偏らず広がっていくようにしています。

このように、配信タイミングは「ユーザーの生活スタイル」に、配信内容は「その人の記憶状態（SM-2）」にそれぞれ最適化し、両者を`DeliverQuestionJob`の自己連鎖の中で1サイクルとして組み合わせています。

### LINE IDTokenのサーバーサイド検証

LIFF画面でユーザーを識別する際、フロントエンドから送られてきた`line_user_id`をそのまま信頼して`session`に保存する実装も可能ですが、これはクライアント側で任意の値に書き換え可能なため、他ユーザーの学習履歴や配信設定に不正アクセスできてしまう脆弱性になります。

そのため、LIFFのSDKが発行する`IDToken`をサーバーサイドでLINEの検証APIに問い合わせ、署名・有効期限・発行者を確認した上で`line_user_id`を取得する実装にしました。

```ruby
# Faradayを使ってLINEのverify APIにIDTokenを送信し、検証済みのline_user_idのみを信頼する
response = Faraday.post("https://api.line.me/oauth2/v2.1/verify") do |req|
  req.headers["Content-Type"] = "application/x-www-form-urlencoded"
  req.body = URI.encode_www_form(
    id_token: id_token,
    client_id: ENV.fetch("LIFF_CHANNEL_ID")
  )
end

result = JSON.parse(response.body)
session[:line_user_id] = result["sub"]
```

クライアントから送られた値を無条件に信頼しない、という基本方針を個人開発でも徹底した点を意識しました。


## ER図

[Gyazoで見る](https://gyazo.com/d315561147dcd91003cfa2bc6ed818a4)

## 画面遷移図

[Figmaで見る](https://www.figma.com/design/8MP2CQfrY8XxY6PfP8wS5h/STUDY-LINE-AI?node-id=0-1&p=f&t=wLo3hfSh2NtX13qJ-0)