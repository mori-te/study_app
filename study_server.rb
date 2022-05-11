#
#
# 簡易WEB学習サイトサーバ
# ruby study_server -o 0.0.0.0
# ruby study_server -e test
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
  json = JSON.parse(request.body.read)
  user = json['user']
  source_file = "/home/#{user}/#{user}.rb"
  File.open(source_file, 'w') do |io|
    io.print(json['source'])
  end
  FileUtils.chown(user, user, [source_file])
  result = nil
  begin
    IO.popen(['su', '-', user, '-c', "ruby #{source_file}", :err => [:child, :out]], 'r') do |io|
      result = io.read
    end
  rescue
    result = $!
  end
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
  p source_file
  p exec_name
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
    p result
  rescue
    result += $!.to_s
  end
  { result: result }.to_json
end

# javascript実行・結果出力
post '/exec_js' do
  json = JSON.parse(request.body.read)
  user = json['user']
  source_file = "/home/#{user}/#{user}.js"
  File.open(source_file, 'w') do |io|
    io.print(json['source'])
  end
  FileUtils.chown(user, user, [source_file])
  result = nil
  begin
    IO.popen(['su', '-', user, '-c', "node #{source_file}", :err => [:child, :out]], 'r') do |io|
      result = io.read
    end
  rescue
    result = $!
  end
  { result: result }.to_json
end

get '/lang' do
  lang, indent, source = $yaml['LANG'][params['lang']]
  { lang: lang, indent: indent, source: source }.to_json
end