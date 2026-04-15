#!/usr/bin/env ruby
# frozen_string_literal: true

# HERP Hire APIを使用してコンタクトを作成し、日程調整URLを生成するスクリプト
#
# 使い方:
#   ruby scripts/herp_create_scheduling.rb \
#     --candidacy-id CANDIDACY_ID \
#     --create-by USER_ID \
#     --contact-type interview \
#     --step casualInterview \
#     --title "カジュアル面談" \
#     --attendee-ids USER_ID1,USER_ID2
#
# 環境変数:
#   HERP_API_KEY: HERP Hire APIキー（必須）

require 'net/http'
require 'json'
require 'uri'
require 'optparse'

class HerpSchedulingCreator
  BASE_URL = 'https://public-api.herp.cloud/hire'

  CONTACT_TYPES = %w[interview meeting document aptitudeTest referenceCheck offerInterview].freeze
  STEPS = %w[entry casualInterview resumeScreening firstInterview secondInterview
             thirdInterview finalInterview offered offerAccepted].freeze

  def initialize
    @api_key = ENV['HERP_API_KEY']
    abort 'エラー: 環境変数 HERP_API_KEY が設定されていません' unless @api_key
  end

  def create_contact(params)
    candidacy_id = params[:candidacy_id]
    uri = URI("#{BASE_URL}/v1/candidacies/#{candidacy_id}/contacts")

    body = build_request_body(params)

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(body)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  def list_users
    uri = URI("#{BASE_URL}/v1/users")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  def get_candidacy(candidacy_id)
    uri = URI("#{BASE_URL}/v1/candidacies/#{candidacy_id}")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  def search_candidacies(name: nil, limit: 20)
    uri = URI("#{BASE_URL}/v1/candidacies")
    query_params = { limit: limit }
    query_params[:name] = name if name
    uri.query = URI.encode_www_form(query_params)

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  private

  def build_request_body(params)
    body = {
      createBy: params[:create_by],
      contact: {
        type: params[:contact_type],
        step: params[:step]
      }
    }

    if params[:share_free_time_slots]
      body[:assessmentSchedule] = {
        type: 'shareFreeTimeSlots',
        adjustBy: params[:adjust_by] || params[:create_by],
        title: params[:title] || 'カジュアル面談',
        description: params[:description] || '',
        attendeeIds: params[:attendee_ids] || [params[:create_by]],
        adjustmentMethod: params[:adjustment_method] || 'all'
      }
    elsif params[:title] && params[:attendee_ids]
      body[:assessmentSchedule] = {
        type: 'register',
        title: params[:title],
        description: params[:description] || '',
        schedule: {
          startsAt: params[:starts_at],
          endsAt: params[:ends_at]
        },
        attendeeIds: params[:attendee_ids],
        calendarSetting: build_calendar_setting(params)
      }
    end

    if params[:evaluation_form_id]
      body[:evaluation] = {
        requesterId: params[:create_by],
        formId: params[:evaluation_form_id],
        evaluatorIds: params[:evaluator_ids] || params[:attendee_ids]
      }
    end

    body
  end

  def build_calendar_setting(params)
    if params[:google_calendar]
      {
        type: 'googleCalendar',
        createMeetingUrl: params[:create_meeting_url] || false
      }
    else
      { type: 'ical' }
    end
  end

  def handle_response(response)
    case response.code.to_i
    when 200, 201
      data = JSON.parse(response.body)
      { success: true, data: data }
    when 401
      { success: false, error: '認証エラー: APIキーが無効です' }
    when 403
      { success: false, error: '権限エラー: この操作を行う権限がありません' }
    when 404
      { success: false, error: 'リソースが見つかりません' }
    when 422
      body = JSON.parse(response.body) rescue {}
      { success: false, error: "バリデーションエラー: #{body}" }
    when 429
      remaining = response['x-remaining-request']
      reset_at = response['x-reset-at']
      { success: false, error: "レート制限超過 (残り: #{remaining}, リセット: #{reset_at})" }
    else
      { success: false, error: "APIエラー (#{response.code}): #{response.body}" }
    end
  end
end

def main
  params = {}

  OptionParser.new do |opts|
    opts.banner = 'Usage: herp_create_scheduling.rb [options]'

    opts.on('--candidacy-id ID', '応募ID（必須）') { |v| params[:candidacy_id] = v }
    opts.on('--create-by ID', 'コンタクト作成者のユーザーID（必須）') { |v| params[:create_by] = v }
    opts.on('--contact-type TYPE', HerpSchedulingCreator::CONTACT_TYPES, "コンタクトタイプ (#{HerpSchedulingCreator::CONTACT_TYPES.join('/')})") { |v| params[:contact_type] = v }
    opts.on('--step STEP', HerpSchedulingCreator::STEPS, "選考ステップ (#{HerpSchedulingCreator::STEPS.join('/')})") { |v| params[:step] = v }
    opts.on('--title TITLE', '選考予定名（1〜50文字）') { |v| params[:title] = v }
    opts.on('--description DESC', '選考予定の詳細（最大1000文字）') { |v| params[:description] = v }
    opts.on('--starts-at TIME', '開始時間（ISO 8601形式）') { |v| params[:starts_at] = v }
    opts.on('--ends-at TIME', '終了時間（ISO 8601形式）') { |v| params[:ends_at] = v }
    opts.on('--attendee-ids IDS', '予定参加者のユーザーID（カンマ区切り）') { |v| params[:attendee_ids] = v.split(',') }
    opts.on('--google-calendar', 'Googleカレンダーを使用') { params[:google_calendar] = true }
    opts.on('--create-meeting-url', 'Google Meet URLを作成') { params[:create_meeting_url] = true }
    opts.on('--share-free-time-slots', '空き日程共有モード（日程調整URLを生成、候補者に時間選択させる）') { params[:share_free_time_slots] = true }
    opts.on('--adjust-by ID', '日程調整者のユーザーID（省略時はcreate-by）') { |v| params[:adjust_by] = v }
    opts.on('--adjustment-method METHOD', %w[all partial], '調整方式 (all/partial、デフォルト: all)') { |v| params[:adjustment_method] = v }
    opts.on('--evaluation-form-id ID', '評価フォームID') { |v| params[:evaluation_form_id] = v }
    opts.on('--evaluator-ids IDS', '評価者のユーザーID（カンマ区切り）') { |v| params[:evaluator_ids] = v.split(',') }
    opts.on('--list-users', 'ユーザー一覧を取得') { params[:action] = :list_users }
    opts.on('--get-candidacy ID', '応募詳細を取得') { |v| params[:action] = :get_candidacy; params[:candidacy_id] = v }
    opts.on('--search NAME', '応募を名前で検索') { |v| params[:action] = :search; params[:search_name] = v }
  end.parse!

  client = HerpSchedulingCreator.new

  result = case params[:action]
           when :list_users
             client.list_users
           when :get_candidacy
             client.get_candidacy(params[:candidacy_id])
           when :search
             client.search_candidacies(name: params[:search_name])
           else
             unless params[:candidacy_id] && params[:create_by] && params[:contact_type] && params[:step]
               abort 'エラー: --candidacy-id, --create-by, --contact-type, --step は必須です'
             end
             client.create_contact(params)
           end

  puts JSON.pretty_generate(result)
end

main if __FILE__ == $PROGRAM_NAME
