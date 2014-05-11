module Fiddlybits
  class CharsetRegistry
    def self.find_by_name(name)
      find_all.find { |c| c.name == name }
    end

    def self.find_all
      if !@all
        all = []
        [ TableCharset, Iso2022Charset, EucCharset ].each do |cls|
          all += cls.constants.map { |c| cls.const_get(c) }.select { |v| v.is_a?(Charset) }
        end
        # Sorting alphanumerics sensibly.
        all.sort_by! { |cs| cs.human_name.upcase.gsub(/\d+/) { |n| "%05d" % n.to_i } }
        @all = all
      end

      @all
    end
  end
end
