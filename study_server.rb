#
#
# 簡易WEB学習サイトサーバ
# bundle exec ruby study_server.rb  -o 0.0.0.0
# bundle exec ruby study_server.rb -e test
#
require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'yaml'
require 'fileutils'

# 初期設定
configure do
  use Rack::Session::Pool
  $yaml = YAML.load_file('master.yaml')
end

# サイトトップ
get '/' do
  erb :index
end

# ruby実行・結果出力
post '/exec_ruby' do
  source_file, user = write_source_file(request.body.read, 'rb')
  result = exec_source_file(source_file, user, 'ruby')
  { result: result }.to_json
end

# java実行・結果出力
post '/exec_java' do
  json = JSON.parse(request.body.read)
  user = json['user']
  source_code = json['source']
  class_name = source_code.scan(/class (\w+)/)[0]
  source_file = "/home/#{user}/#{class_name[0]}.java"
  class_file = "/home/#{user}/#{class_name[0]}.class"
  exec_name = File.basename(source_file, '.*')

  File.open(source_file, 'w') do |io|
    io.print(json['source'])
  end
  FileUtils.chown(user, user, [source_file])
  begin
    FileUtils.rm(class_file)
  rescue
  end

  result = ''
  begin
    IO.popen(['su', '-', user, '-c', "javac #{source_file} && java #{exec_name}", :err => [:child, :out]], 'r') do |io|
      result = io.read
      result.force_encoding('CP932') if RUBY_PLATFORM =~ /mingw|mswin/
    end
  rescue
    result += $!.to_s
  end
  { result: result }.to_json
end

# javascript実行・結果出力
post '/exec_js' do
  source_file, user = write_source_file(request.body.read, 'js')
  result = exec_source_file(source_file, user, 'node')
  { result: result }.to_json
end

# python実行・結果出力
post '/exec_python' do
  source_file, user = write_source_file(request.body.read, 'py')
  result = exec_source_file(source_file, user, 'python3.10')
  { result: result }.to_json
end

# go実行・結果出力
post '/exec_golang' do
  source_file, user = write_source_file(request.body.read, 'go')
  result = exec_source_file(source_file, user, 'go run')
  { result: result }.to_json
end

get '/lang' do
  lang, indent, source = $yaml['LANG'][params['lang']]
  { lang: lang, indent: indent, source: source }.to_json
end

# ファイルアップロード
post '/upload' do
  name = params[:file][:filename]
  body = params[:file][:tempfile]
  user = params[:user]
  file_path = "/home/#{user}/#{name}"
  File.open(file_path, 'w') do |io|
    io.print(body.read)
  end
  FileUtils.chown(user, user, [file_path])
  ""
end

# 共通処理
def write_source_file(body, suffix)
  json = JSON.parse(body)
  user = json['user']
  source_file = "/home/#{user}/#{user}.#{suffix}"
  File.open(source_file, 'w') do |io|
    io.print(json['source'])
  end
  FileUtils.chown(user, user, [source_file])
  [source_file, user]
end

def exec_source_file(source_file, user, cmd)
  result = nil
  begin
    IO.popen(['su', '-', user, '-c', "#{cmd} #{source_file}", :err => [:child, :out]], 'r') do |io|
      result = io.read
    end
  rescue
    result = $!
  end
  result
end
