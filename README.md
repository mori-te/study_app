# 起動方法

linuxのrootで任意の場所にインストールしてください。  
初期ユーザはmori-teになってます。（linux上に`adduser mori-te`してください）

```shell
bundle exec ruby study_server.rb -e test
```
suコマンドを使用しているのでwindowsでは動きません。

```
http://<ip address or FQDN>:4567/
```