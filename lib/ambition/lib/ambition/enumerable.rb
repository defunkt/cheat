module Ambition
  module Enumerable
    include ::Enumerable

    def each(&block)
      find(:all, query_context.to_hash).each(&block)
    end
  end
end
