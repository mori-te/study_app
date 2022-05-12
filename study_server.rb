#
#
# 簡易WEB学習サイトサーバ
#
#
require 'sinatra'           # gem install sinatra webrick
require 'sinatra/reloader'  # gem install sinatra-contrib
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
  source_file = "source/#{json['user']}.rb"
  File.open(source_file, 'w') do |io|
    io.print(json['source'])
  end
  result = nil
  begin
    IO.popen(['ruby', source_file, :err => [:child, :out]], 'r') do |io|
      result = io.read.gsub(/^source\//, "")
    end
  rescue
    result = $!
  end
  { result: result }.to_json
end

# java実行・結果出力
post '/exec_java' do
  json = JSON.parse(request.body.read)
  source_code = json['source']
  class_name = source_code.scan(/class (\w+)/)[0]
  source_file = "#{class_name[0]}.java"

  File.open("source/#{source_file}", 'w') do |io|
    io.print(json['source'])
  end
  result = ''
  FileUtils.cd('source')
  begin
    IO.popen(["javac", source_file, :err => [:child, :out]], 'r') do |io|
      result = io.read
      result.force_encoding('CP932') if RUBY_PLATFORM =~ /mingw|mswin/
    end
    IO.popen(['java', source_file.sub(".java", ""), :err => [:child, :out]], 'r') do |io|
      buf = io.read
      buf.force_encoding('CP932') if RUBY_PLATFORM =~ /mingw|mswin/ # for Windows
      result += buf
    end
  rescue
    result += $!.to_s
  end
  FileUtils.cd('..')
  { result: result }.to_json
end

# javascript実行・結果出力
post '/exec_js' do
  json = JSON.parse(request.body.read)
  source_file = "source/#{json['user']}.js"
  File.open(source_file, 'w') do |io|
    io.print(json['source'])
  end
  result = nil
  begin
    IO.popen(['node', source_file, :err => [:child, :out]], 'r') do |io|
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