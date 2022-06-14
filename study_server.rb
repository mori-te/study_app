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
  result = exec_source_file(user, "ruby #{source_file}")
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

  result = exec_source_file(user, "javac #{source_file} && java #{exec_name}")
  { result: result }.to_json
end

# javascript実行・結果出力
post '/exec_js' do
  source_file, user = write_source_file(request.body.read, 'js')
  result = exec_source_file(user, "node #{source_file}")
  { result: result }.to_json
end

# python実行・結果出力
post '/exec_python' do
  source_file, user = write_source_file(request.body.read, 'py')
  result = exec_source_file(user, "python3.10 #{source_file}")
  { result: result }.to_json
end

# go実行・結果出力
post '/exec_golang' do
  source_file, user = write_source_file(request.body.read, 'go')
  result = exec_source_file(user, "go run #{source_file}")
  { result: result }.to_json
end

# COBOL実行・結果出力
post '/exec_cobol' do
  source_file, user = write_source_file(request.body.read, 'cbl')
  result = exec_source_file(user, "cobc -x #{source_file} && #{source_file.sub('.cbl', '')}")
  { result: result }.to_json
end

# CASL2実行・結果出力
post '/exec_casl2' do
  source_file, user = write_source_file(request.body.read, 'cas')
  result = exec_source_file(user, "node-casl2 #{source_file} && node-comet2 -r #{source_file.sub('.cas', '.com')}")
  { result: result }.to_json
end

# C言語実行・結果出力
post '/exec_clang' do
  source_file, user = write_source_file(request.body.read, 'c')
  result = exec_source_file(user, "cc #{source_file} && ./a.out")
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

def exec_source_file(user, cmd)
  result = nil
  begin
    IO.popen(['su', '-', user, '-c', "#{cmd}", :err => [:child, :out]], 'r+') do |io|
      # 標準入力データ
      File.open("/home/#{user}/.input.txt", "r").each do |buf|
        io.print(buf)
      end
      io.close_write
      result = io.read
    end
  rescue
    result = $!
  end
  result
end

def set_stdin_file(user, input_data)
  input_data_file = "/home/#{user}/.input.txt"
  File.open(input_data_file, "w") do |io|
    input_data.each do |dat|
      io.puts(dat)
    end
  end
  FileUtils.chown(user, user, [input_data_file])
end