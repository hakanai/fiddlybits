module Fiddlybits
  class CharsetRegistry
    def self.find_by_name(name)
      find_all.find { |c| c.name == name }
    end

    def self.find_all
      if !@all
        all = []
        [ Iso2022Charset, TableCharset, AsciiCharset ].each do |cls|
          all += cls.constants.sort.map { |c| cls.const_get(c) }.select { |v| v.is_a?(Charset) }
        end
        all.sort_by! { |cs| cs.name }
        @all = all
      end

      @all
    end
  end
end
