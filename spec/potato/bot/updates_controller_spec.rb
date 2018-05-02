RSpec.describe Potato::Bot::UpdatesController do
  include_context 'potato/bot/updates_controller'
  let(:other_bot_name) { 'other_bot' }

  describe '.action_for_command' do
    subject { ->(*args) { described_class.action_for_command(*args) } }

    def assert_subject(input, expected)
      expect(subject.call input).to eq expected
    end

    it 'bypasses and downcases not conflictint commands' do
      assert_subject 'test', 'test'
      assert_subject 'TeSt', 'test'
      assert_subject '_Te1St', '_te1st'
    end

    it 'adds _on to conflicting commands' do
      described_class::PAYLOAD_TYPES.each do |x|
        assert_subject x, "on_#{x}"
        assert_subject x.upcase, "on_#{x}"
      end
      assert_subject '1TeSt', 'on_1test'
    end
  end

  describe '.command_from_text' do
    subject { ->(*args) { described_class.command_from_text(*args) } }

    def assert_subject(input, cmd, *args)
      expected = cmd ? [cmd, args] : cmd
      expect(subject.call(*input)).to eq expected
    end

    let(:max_cmd_size) { 32 }
    let(:long_cmd) { 'a' * (max_cmd_size - 1) }
    let(:too_long_cmd) { 'a' * max_cmd_size }

    it 'works for simple commands' do
      assert_subject '/test', 'test'
      assert_subject '/tE_2_St', 'tE_2_St'
      assert_subject '/123', '123'
      assert_subject "/#{long_cmd}", long_cmd
    end

    it 'works for simple messages' do
      assert_subject 'text', nil
      assert_subject ' ', nil
      assert_subject ' text', nil
      assert_subject ' 1', nil
      assert_subject ' /text', nil
      assert_subject '/te-xt', nil
      assert_subject 'text /cmd ', nil
      assert_subject "/#{too_long_cmd}", nil
    end

    it 'works for mentioned commands' do
      assert_subject ['/test@bot', 'bot'], 'test'
      assert_subject ['/test@otherbot', 'bot'], nil
      assert_subject ['/test@Bot', 'bot'], nil
      assert_subject '/test@bot', nil
      assert_subject ['/test@bot', true], 'test'
      assert_subject ['/test@otherbot', true], 'test'
    end

    it 'works for commands with args' do
      assert_subject '/test arg', 'test', 'arg'
      assert_subject '/test  arg  1  2', 'test', 'arg', '1', '2'
      assert_subject ['/test@bot arg', 'bot'], 'test', 'arg'
      assert_subject ['/test@otherbot arg', 'bot'], nil
      assert_subject '/test@bot arg', nil
    end

    it 'works for commands with multiline args' do
      assert_subject "/test arg\nother", 'test', 'arg', 'other'
      assert_subject "/test one\ntwo\n\nthree", 'test', 'one', 'two', 'three'
    end
  end

  describe '#action_for_payload' do
    subject { controller.action_for_payload }

    def stub_payload(*fields)
      Hash[fields.map { |x| [x, double(x)] }]
    end

    context 'when payload is inline_query' do
      let(:payload_type) { 'inline_query' }
      let(:payload) { stub_payload(:id, :from, :location, :query, :offset) }
      it { should eq [false, payload_type, payload.values_at(:query, :offset)] }
    end

    context 'when payload is chosen_inline_result' do
      let(:payload_type) { 'chosen_inline_result' }
      let(:payload) { stub_payload(:result_id, :from, :location, :inline_message_id, :query) }
      it { should eq [false, payload_type, payload.values_at(:result_id, :query)] }
    end

    context 'when payload is callback_query' do
      let(:payload_type) { 'callback_query' }
      let(:payload) { stub_payload(:id, :from, :message, :inline_message_id, :data) }
      it { should eq [false, payload_type, payload.values_at(:data)] }
    end

    context 'when payload is not supported' do
      let(:payload_type) { '_unsupported_' }
      it { should eq [false, :unsupported_payload_type, []] }
    end

    %w[message channel_post].each do |type|
      context "when payload is edited_#{type}" do
        let(:payload_type) { "edited_#{type}" }
        it { should eq [false, payload_type, [payload]] }
      end

      context 'when payload is message' do
        let(:payload_type) { type }
        let(:payload) { {'text' => text} }
        let(:text) { 'test' }

        it { should eq [false, payload_type, [payload]] }

        context 'with command' do
          let(:text) { "/test#{"@#{mention}" if mention} arg 1 2" }
          let(:mention) {}
          it { should eq [true, 'test', %w[arg 1 2]] }

          context 'with mention' do
            let(:mention) { bot.username }
            it { should eq [true, 'test', %w[arg 1 2]] }
          end

          context 'with mention for other bot' do
            let(:mention) { other_bot_name }
            it { should eq [false, payload_type, [payload]] }
          end
        end

        context 'without text' do
          let(:payload) { {'audio' => {'file_id' => 123}} }
          it { should eq [false, payload_type, [payload]] }
        end
      end
    end

    custom_payload_types = %w[
      message
      edited_message
      channel_post
      edited_channel_post
      inline_query
      chosen_inline_result
      callback_query
    ]
    (described_class::PAYLOAD_TYPES - custom_payload_types).each do |type|
      context "when payload is #{type}" do
        let(:payload_type) { type }
        it { should eq [false, payload_type, [payload]] }
      end
    end
  end

  context 'when `update` is a virtus model' do
    subject { controller }
    let(:update) { Potato::Bot::Types::Update.new(super()) }
    %w[
      message
      inline_query
      chosen_inline_result
    ].each do |type|
      context "with #{type}" do
        type_class = Potato::Bot::Types.const_get(type.camelize)
        let(:payload_type) { type }
        let(:payload) { {} }
        its(:payload_type) { should eq payload_type }
        its(:payload) { should be_instance_of type_class }
      end
    end
  end

  describe '#bot_username' do
    subject { controller.bot_username }

    context 'when bot is not set' do
      let(:bot) {}
      it { should eq nil }
    end

    context 'when bot is set' do
      let(:bot) { double(username: double(:username)) }
      it { should eq bot.username }
    end
  end

  describe '#process' do
    subject { -> { controller.process(:action, *args) } }
    let(:args) { %i[arg1 arg2] }
    let(:controller_class) do
      Class.new(described_class) do
        attr_reader :acted, :hooked

        def action(*args)
          @acted = true
          [from, chat, args]
        end
      end
    end

    context 'when action is protected' do
      before { controller_class.send :protected, :action }
      its(:call) { should eq nil }

      context 'when action_missing defined' do
        before do
          controller.class_eval do
            protected

            def action_missing(*args)
              args
            end
          end
        end

        its(:call) { should eq ['action', *args] }
      end
    end

    context 'when callbacks are defined' do
      before do
        controller_class.class_eval do
          before_action :hook, only: :action
          attr_reader :hooked

          private

          def hook
            @hooked = true
          end
        end
      end

      it { should change(controller, :hooked).to true }
      it { should change(controller, :acted).to true }
      its(:call) { should eq [nil, nil, args] }

      context 'when callback halts chain' do
        before do
          controller_class.prepend(Module.new do
            def hook
              super
              ActiveSupport::VERSION::MAJOR >= 5 ? throw(:abort) : false
            end
          end)
        end

        it { should change(controller, :hooked).to true }
        it { should_not change(controller, :acted).from nil }
        its(:call) { should eq false }
      end
    end

    context 'when initialized without update' do
      let(:controller) { controller_class.new(bot, from: from, chat: chat) }
      let(:from) { {'id' => 'user_id'} }
      let(:chat) { {'id' => 'chat_id'} }
      its(:call) { should eq [from, chat, args] }
    end
  end

  describe '#initialize' do
    subject { controller }
    let(:payload_type) { 'message' }
    let(:payload) { deep_stringify(chat: chat, from: from) }
    let(:chat) { double(:chat) }
    let(:from) { double(:from) }

    def self.with_reinitialize(&block)
      instance_eval(&block)
      context 'when re-initialized' do
        let(:controller) do
          described_class.new(double(:other_bot), build_update(:message,
            text: 'original message',
            from: double(:original_from),
            chat: double(:original_chat),
          )).tap { |x| x.send(:initialize, bot, update) }
        end
        instance_eval(&block)
      end
    end

    context 'when update is given' do
      with_reinitialize do
        its(:bot) { should eq bot }
        its(:update) { should eq update }
        its(:payload) { should eq payload }
        its(:payload_type) { should eq payload_type }
        its(:from) { should eq from }
        its(:chat) { should eq chat }
      end
    end

    context 'when options hash is given' do
      let(:update) { {from: from, chat: chat} }
      with_reinitialize do
        its(:bot) { should eq bot }
        its(:update) { should eq nil }
        its(:payload) { should eq nil }
        its(:payload_type) { should eq nil }
        its(:from) { should eq from }
        its(:chat) { should eq chat }
      end
    end
  end

  describe '#chat' do
    subject { controller.chat }
    let(:payload_type) { :message }
    let(:payload) { {chat: 'test_value'} }
    it { should eq payload[:chat] }

    context 'when payload is not set' do
      let(:payload) {}
      it { should eq nil }
    end

    context 'when payload has no such field' do
      let(:payload) { {smth: 'other'} }
      it { should eq nil }

      context 'but has `message`' do
        let(:payload) { {message: message} }
        let(:message) { {text: 'Hello bot!'} }
        it { should eq nil }

        context 'with `chat` set' do
          let(:message) { super().merge(chat: 'test value') }
          it { should eq message[:chat] }
        end
      end
    end
  end

  describe '#from' do
    subject { controller.from }
    let(:payload_type) { :message }
    let(:payload) { {from: 'test_value'} }
    it { should eq payload[:from] }

    context 'when payload is not set' do
      let(:payload) {}
      it { should eq nil }
    end

    context 'when payload has no such field' do
      let(:payload) { {smth: 'other'} }
      it { should eq nil }
    end
  end
end
