module Ambition
  module Limit
    def first(limit = 1, offset = nil)
      query_context.add LimitProcessor.new(limit, offset)
      find(limit == 1 ? :first : :all, query_context.to_hash)
    end

    def [](offset, limit)
      first(offset, limit)
    end
  end

  class LimitProcessor 
    def initialize(*args)
      @args = args
    end

    def prefix
      'LIMIT '
    end

    def key
      :limit
    end

    def join_string
      ', '
    end

    def to_sql
      "LIMIT #{to_s}"
    end

    def to_s
      @args.compact * ', '
    end
  end
end
