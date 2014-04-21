require 'ostruct'

module Fiddlybits
  class InvalidEncoding < RuntimeError ; end

  class Encoding
    attr_reader :name
    attr_reader :human_name

    # @param name [String] the short name of the encoding (used like a unique ID.)
    # @param human_name [String] the name of the encoding for people to read.
    def initialize(name, human_name)
      @name = name
      @human_name = human_name
    end
    
    def self.find_by_name(name)
      find_all.find { |e| e.name == name }
    end

    def self.find_all
      if !@all
        all = []
        [ Base16Encoding, Base32Encoding, Base64Encoding,
          Ascii85Encoding,
          UuencodeEncoding, QuotedPrintableEncoding
        ].each do |cls|
          all += cls.constants.sort.map { |c| cls.const_get(c) }.select { |v| v.is_a?(Encoding) }
        end
        all.sort_by! { |cs| cs.name }
        @all = all
      end

      @all
    end
  end
end
