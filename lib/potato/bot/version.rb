module Potato
  module Bot
    VERSION = '0.1.0'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
