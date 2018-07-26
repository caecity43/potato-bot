RSpec.shared_context 'potato/bot/integration' do
  let(:bot) { Potato.bot }
  let(:default_message_options) { {from: from, chat: chat} }
  let(:from) { {id: from_id} }
  let(:from_id) { 123 }
  let(:chat) { {id: chat_id} }
  let(:chat_id) { 456 }
  let(:controller_path) do
    route_name = Potato::Bot::RoutesHelper.route_name_for_bot(bot)
    Rails.application.routes.url_helpers.public_send("#{route_name}_path")
  end
  let(:request_headers) do
    {
      'ACCEPT' => 'application/json',
      'Content-Type' => 'application/json',
    }
  end
  let(:clear_session?) { described_class.respond_to?(:session_store) }
  before { described_class.session_store.try!(:clear) if clear_session? }

  include Potato::Bot::RSpec::ClientMatchers

  def dispatch(update)
    if ActionPack::VERSION::MAJOR >= 5
      post(controller_path, params: update.to_json, headers: request_headers)
    else
      post(controller_path, update.to_json, request_headers)
    end
  end

  def dispatch_message(text, options = {})
    dispatch message: default_message_options.merge(options).merge(text: text)
  end

  def dispatch_command(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    dispatch_message("/#{args.join ' '}", options)
  end

  # Matcher to check response. Make sure to define `let(:chat_id)`.
  def respond_with_message(expected = Regexp.new(''))
    raise 'Define chat_id to use respond_with_message' unless defined?(chat_id)
    send_potato_message(bot, expected, chat_id: chat_id)
  end
end

RSpec.shared_context 'potato/bot/callback_query', callback_query: true do
  include_context 'potato/bot/integration'

  subject { -> { dispatch callback_query: payload } }
  let(:payload) { {id: 11, from: from, message: message, data: data} }
  let(:message) { {message_id: 22, chat: chat, text: 'message text'} }

  # Matcher to check that origin message got edited.
  def edit_current_message(type, options = {})
    description = 'edit current message'
    options = options.merge(
      message_id: message[:message_id],
      chat_id: chat_id,
    )
    Potato::Bot::RSpec::ClientMatchers::MakePotatoRequest.new(
      bot, :"editMessage#{type.to_s.camelize}", description: description
    ).with(hash_including(options))
  end

  # Matcher to check that callback query is answered.
  def answer_callback_query(text = Regexp.new(''), options = {})
    description = "answer callback query with #{text.inspect}"
    text = a_string_matching(text) if text.is_a?(Regexp)
    options = options.merge(
      inline_message_id: payload[:inline_message_id],
      text: text,
    )
    # Rails.logger.info "-----------Integration.answer_callback_query"
    # Rails.logger.info options.inspect
    Potato::Bot::RSpec::ClientMatchers::MakePotatoRequest.new(
      bot, :answerCallbackQuery, description: description
    ).with(hash_including(options))
  end
end

RSpec.configure do |config|
  if config.respond_to?(:include_context)
    config.include_context 'potato/bot/integration', :potato_bot
    config.include_context 'potato/bot/callback_query', :potato_bot, :callback_query
  end
end
