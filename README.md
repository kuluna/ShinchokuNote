# 進捗ノート(Shinchoku Note/ Progress notebooks)

進捗ノートは、同人製作者のためのツールです。

## 環境(Environments)

+ Ruby 2.3.1
+ Rails 5.1.4
+ puma 3.7
+ nginx

## リリースノート(Release Notes)

### ver 0.1.0

2018/5/4
(正式には4/29(進捗の日))
ベータ版最初のリリース

### ver 0.1.1

2018/5/5

+ 画像投稿フォームにマウスを載せる際にカーソルが変わるように
+ 「おまかせ表示」をした際に一瞬他のページが見える現象の修正(キャッシュの無効化)
+ コメントや投稿の改行を正しく表示するように
+ コメントや投稿で長い英単語を打った場合にはみ出ない(改行される)ように
+ 通知ページの表示からその通知元のノートに飛べるようにリンクを設置
+ リリースノートを追加

### ver 0.1.2

2018/5/8

+ 新規進捗投稿時の「URLから紐付け」が正常にできない問題の修正
+ 文字数の多い新規投稿を行おうとするとエラーになる問題の修正(文字数の制限)
+ 新規投稿やコメントへの返信時に文字数を表示
+ 細かいバグの修正

## クラス構成(Classes)

詳細な構成はdocs/shinchokunote.astaをご覧ください。

### Userクラス

ユーザ情報を格納するクラスです。Userは複数のNoteを持ちます。

### Noteクラス

情報をまとめるノートクラスです。基本的に抽象クラス扱いであり、ここから様々な種類のNoteが派生します。Postの投稿、Commentの受付、ShinchokuDodeskaの受付、ウォッチリストへの登録が可能です。

### Projectクラス < Note

自分の進めているプロジェクトを表すクラスです。

### RequestBoxクラス < Note

コメントを受け付けるためのノートを表すクラスです。

### Postクラス

進捗報告などの投稿一つ一つを表すクラスです。

### TweetPostクラス < Post

Twitterに投稿されたツイートをそのままPostとして扱うことができます。
基本的に当サービスのPostはTweetPostです。

+ Commentクラス

Noteに対しコメントすることができます。

+ Shinchokudodeskaクラス

Noteに対し「進捗どうですか」のアクションを行うことができます。

+ UserWatchesNoteクラス

ウォッチリスト用の多対多構造作成用のクラスです。
