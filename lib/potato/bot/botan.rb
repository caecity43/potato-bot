module Potato
  module Bot
    class Botan
      TRACK_URI = 'https://api.potato.im/track'.freeze

      autoload :ClientHelpers, 'potato/bot/botan/client_helpers'
      autoload :ControllerHelpers, 'potato/bot/botan/controller_helpers'
      class Error < Bot::Error; end

      extend Initializers
      prepend Async
      include DebugClient

      class << self
        def by_id(id)
          Potato.botans[id]
        end

        def prepare_async_args(method, uri, query = {}, body = nil)
          [method.to_s, uri.to_s, Async.prepare_hash(query), body]
        end
      end

      attr_reader :client, :token

      def initialize(token = nil, **options)
        @client = HTTPClient.new
        @token = token || options[:token]
      end

      def track(event, uid, payload = {})
        request(:post, TRACK_URI, {name: event, uid: uid}, payload.to_json)
      end

      def request(method, uri, query = {}, body = nil)
        res = http_request(method, uri, query.merge(token: token), body)
        status = res.status
        return JSON.parse(res.body) if status < 300
        result = JSON.parse(res.body) rescue nil # rubocop:disable RescueModifier
        err_msg = "#{res.reason}: #{result && result['info'] || '-'}"
        raise Error, err_msg
      end

      def http_request(method, uri, query, body)
        client.request(method, uri, query, body)
      end

      def inspect
        "#<#{self.class.name}##{object_id}(#{@id})>"
      end
    end
  end
end
