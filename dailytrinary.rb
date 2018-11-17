# coding: utf-8
require 'bundler/setup'
require 'mechanize'
require 'mastodon'
require 'json'
require 'dotenv'

Dotenv.load

if !ENV["MASTODON_URL"] || !ENV["MASTODON_ACCESS_TOKEN"]
  STDERR.puts "missing env value"
  exit 1
end

FILE_NAME = "latest.txt"
BLOG_URL = "https://d00030400.gamecity.ne.jp/a_girl/www/official/blog/"

if File.exist?(FILE_NAME)
  saved_content = File.open(FILE_NAME, 'r') do |io|
    JSON.load(io, nil, { symbolize_names: true })
  end
else
  saved_content = { date: "", title: "" }
end

agent = Mechanize.new
agent.user_agent_alias = 'Android'

page = agent.get(BLOG_URL)
top = page.css(".day_cont").first
latest_content = {
  date: top.css(".day_text").first.text.strip,
  title: top.css(".co_title_text").first.text.strip
}

puts latest_content

File.open(FILE_NAME, 'w') do |io|
  JSON.dump(latest_content, io)
end

if saved_content == latest_content
  puts "no update."
  exit
end

notify_text = <<EOS
[NOTICE] デイトラ！の更新を発見しました。
Date: #{ latest_content[:date] }
Title: #{ latest_content[:title] }
#{ BLOG_URL }
EOS

don_client = Mastodon::REST::Client.new(base_url: ENV["MASTODON_URL"], bearer_token: ENV["MASTODON_ACCESS_TOKEN"])
response = don_client.create_status(notify_text, visibility: 'unlisted')

p response
