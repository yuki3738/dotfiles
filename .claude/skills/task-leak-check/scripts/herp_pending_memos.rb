#!/usr/bin/env ruby
# frozen_string_literal: true

# HERP Hire API を使って、指定したユーザーがoperatorに入っていて
# かつ note（メモ）が空の候補者一覧を出力する。
#
# 使い方:
#   ruby herp_pending_memos.rb --operator-id U-L0EK3
#   ruby herp_pending_memos.rb --email y.minamiya@mov.am
#
# 環境変数:
#   HERP_API_KEY     : HERP Hire APIキー（必須）
#   HERP_MY_USER_ID  : デフォルトのoperator ID（任意、--operator-id優先）

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

def resolve_operator_id(email)
  (1..MAX_PAGES).each do |page|
    data = api_get('/v1/users', page: page)
    users = data['users'] || []
    break if users.empty?
    hit = users.find { |u| (u['email'] || '').downcase == email.downcase }
    return hit['id'] if hit
    break unless data['hasNextPage']
  end
  nil
end

def all_candidacies_with_empty_note(operator_id)
  results = []
  (1..MAX_PAGES).each do |page|
    data = api_get('/v1/candidacies', page: page)
    cands = data['candidacies'] || []
    break if cands.empty?
    cands.each do |c|
      next unless c['status'] == 'active'
      next unless (c['operators'] || []).include?(operator_id)
      note = c['note']
      next if note && !note.strip.empty?
      results << c
    end
    break unless data['hasNextPage']
  end
  results
end

def main
  opts = { operator_id: ENV['HERP_MY_USER_ID'] }
  OptionParser.new do |o|
    o.on('--operator-id ID', 'HERPユーザーID（operator）') { |v| opts[:operator_id] = v }
    o.on('--email EMAIL', 'ユーザーのemailから逆引き') { |v| opts[:email] = v }
  end.parse!

  unless ENV['HERP_API_KEY']
    abort 'エラー: HERP_API_KEY が未設定です'
  end

  operator_id = opts[:operator_id]
  if operator_id.nil? || operator_id.empty?
    if opts[:email]
      operator_id = resolve_operator_id(opts[:email])
      abort "ユーザーが見つかりません: #{opts[:email]}" unless operator_id
    else
      abort '--operator-id または --email を指定してください'
    end
  end

  candidacies = all_candidacies_with_empty_note(operator_id)

  output = {
    operator_id: operator_id,
    count: candidacies.size,
    candidacies: candidacies.map do |c|
      {
        id: c['id'],
        name: c['name'],
        step: c['step'],
        appliedAt: c['appliedAt'],
        updatedAt: c['updatedAt'],
        url: "https://movinc.v1.herp.cloud/ats/p/candidacies/#{c['id']}"
      }
    end
  }
  puts JSON.pretty_generate(output)
end

main if __FILE__ == $PROGRAM_NAME
