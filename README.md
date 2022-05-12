# 起動手順

## インストール

https://rubyinstaller.org/downloads/ のRuby+Devkit 3.1.2-1 (x64) をインストールする。

ライブラリをインストールするため以下を実行

```
> gem install webrick
> gem install sinatra
> gem install sinatra-contrib
```

javaとnodejsもインストールする必要がある。


## 起動方法

```
> mkdir source
> ruby study_server.rb -e test
```

## アクセス

```
http://localhost:4567/
```