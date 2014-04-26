module Fiddlybits
  # Interface to mark immutable classes.
  module Immutable
    # Nothing to do, by definition.
    def deep_freeze
      self
    end
  end
end