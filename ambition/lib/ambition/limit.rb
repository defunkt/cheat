module Ambition
  module Limit
    def first(limit = 1, offset = nil)
      query_context.add LimitProcessor.new(limit, offset)
      find(limit == 1 ? :first : :all, query_context.to_hash)
    end

    def [](offset, limit = nil)
      return first(offset, limit) if limit

      if offset.is_a? Range
        limit  = offset.end
        limit -= 1 if offset.exclude_end?
        first(offset.first, limit - offset.first)
      else
        first(offset, 1)
      end
    end
  end

  class LimitProcessor 
    def initialize(*args)
      @args = args
    end

    def key
      :limit
    end

    def to_s
      @args.compact * ', '
    end
  end
end
