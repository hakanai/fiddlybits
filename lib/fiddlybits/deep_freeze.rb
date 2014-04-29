module Fiddlybits
  module DeepFreeze
    refine Object do
      def deep_freeze
        # It's safer to get an exception then to assume freeze() will be adequate for new types of enumerable.
        raise "Unsupported object for deep freeze: #{self.inspect} (class #{self.class})"
      end
    end

    # Classes where freeze is enough
    # (at least in our case. A more general solution might look at the instance variables.)
    [ String, Symbol, TrueClass, FalseClass, NilClass, Integer ].each do |c|
      refine c do
        def deep_freeze
          freeze
        end
      end
    end

    refine Array do
      def deep_freeze
        each { |k, v| k.deep_freeze; v.deep_freeze }
        freeze
      end
    end

    refine Hash do
      def deep_freeze
        each { |v| v.deep_freeze }
        freeze
      end
    end
  end
end
