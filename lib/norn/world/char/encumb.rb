require "norn/util/memory-store"
require "norn/util/percentage"

module Norn
  class Encumb < MemoryStore
    include Percentage

    def level
      fetch(:level, :none)
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.is_boolean_method? || super
    end

    def method_missing(*args)
      return level.eql?(args.first.from_boolean_method) if args.first.is_boolean_method?
      super *args
    end
  end
end