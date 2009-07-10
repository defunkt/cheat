module Ambition
  module Count
    def size
      count(query_context.to_hash)
    end
    alias_method :length, :size
  end
end
