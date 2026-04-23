#!/usr/bin/env ruby
# frozen_string_literal: true

# HERP Hire API を使って、メモ（note）が空の active 候補者の件数を出力する。
#
# 使い方:
#   ruby herp_pending_memos.rb              # 全 active 候補者のうちメモ空の件数
#   ruby herp_pending_memos.rb --verbose    # 件数＋候補者一覧
#
# 環境変数:
#   HERP_API_KEY : HERP Hire APIキー（必須）

require 'net/http'
require 'json'
require 'uri'
require 'optparse'

BASE_URL = 'https://public-api.herp.cloud/hire'
MAX_PAGES = 50

def api_get(path, query = {})
  uri = URI("#{BASE_URL}#{path}")
  uri.query = URI.encode_www_form(query) unless query.empty?
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{ENV.fetch('HERP_API_KEY')}"
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  abort "HERP APIエラー #{res.code}: #{res.body[0, 200]}" unless res.code.start_with?('2')
  JSON.parse(res.body)
end

def all_active_candidacies_with_empty_note
  results = []
  (1..MAX_PAGES).each do |page|
    data = api_get('/v1/candidacies', page: page)
    cands = data['candidacies'] || []
    break if cands.empty?
    cands.each do |c|
      next unless c['status'] == 'active'
      note = c['note']
      next if note && !note.strip.empty?
      results << c
    end
    break unless data['hasNextPage']
  end
  results
end

def main
  opts = { verbose: false }
  OptionParser.new do |o|
    o.on('--verbose', '候補者一覧も出力') { opts[:verbose] = true }
  end.parse!

  abort 'エラー: HERP_API_KEY が未設定です' unless ENV['HERP_API_KEY']

  candidacies = all_active_candidacies_with_empty_note

  output = { count: candidacies.size }

  if opts[:verbose]
    output[:candidacies] = candidacies.map do |c|
      {
        id: c['id'],
        name: c['name'],
        step: c['step'],
        operators: c['operators'],
        appliedAt: c['appliedAt'],
        url: "https://movinc.v1.herp.cloud/ats/p/candidacies/#{c['id']}"
      }
    end
  end

  puts JSON.pretty_generate(output)
end

main if __FILE__ == $PROGRAM_NAME
