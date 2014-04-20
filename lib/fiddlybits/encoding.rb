require 'base64'
require 'ostruct'

module Fiddlybits
  class Encoding
    def self.find_by_name(name)
      find_all.find { |e| e.name == name }
    end

    def self.find_all
      if !@all
        @all = [
          OpenStruct.new(
            name: 'base64',
            human_name: Base64,
            encode: proc { |x| Base64.encode64(x) },
            decode: proc { |x| Base64.decode64(x) }
          )
        ]
      end
      @all
    end
  end
end
