module Ambition
  class Query
    @@select = 'SELECT * FROM %s %s'

    def initialize(owner)
      @table_name = owner.table_name
      @owner      = owner
      @clauses    = []
    end

    def add(clause) 
      @clauses << clause
      self
    end

    def query_context 
      self
    end

    def method_missing(method, *args, &block) 
      with_context do
        @owner.send(method, *args, &block)
      end
    end

    def with_context 
      @owner.query_context = self
      ret = yield
    ensure
      @owner.query_context = nil
      ret
    end

    def to_hash
      keyed = keyed_clauses
      hash  = {}

      unless (where = keyed[:conditions]).blank?
        hash[:conditions] = Array(where)
        hash[:conditions] *= ' AND '
      end

      unless (includes = keyed[:includes]).blank?
        hash[:includes] = includes.flatten
      end

      if order = keyed[:order]
        hash[:order] = order.join(', ')
      end

      if limit = keyed[:limit]
        hash[:limit] = limit.join(', ')
      end

      hash
    end

    def to_s
      hash = keyed_clauses

      sql = []
      sql << "JOIN #{hash[:includes].join(', ')}"       unless hash[:includes].blank?
      sql << "WHERE #{hash[:conditions].join(' AND ')}" unless hash[:conditions].blank?
      sql << "ORDER BY #{hash[:order].join(', ')}"      unless hash[:order].blank?
      sql << "LIMIT #{hash[:limit].join(', ')}"         unless hash[:limit].blank?

      @@select % [ @table_name, sql.join(' ') ]
    end
    alias_method :to_sql, :to_s

    def keyed_clauses
      @clauses.inject({}) do |hash, clause|
        hash[clause.key] ||= []
        hash[clause.key] << clause.to_s

        if clause.respond_to?(:includes) && !clause.includes.blank?
          hash[:includes] ||= []
          hash[:includes] << clause.includes
        end

        hash
      end
    end
  end
end
