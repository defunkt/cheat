module Ambition
  module Where
    def select(*args, &block)
      ##
      # XXX: AR::Base hack / workaround
      if args.empty?
        query_context.add WhereProcessor.new(self, block)
      else
        super
      end
    end

    def detect(&block)
      select(&block).first
    end
  end

  class WhereProcessor < Processor 
    attr_reader :includes

    def initialize(owner, block)
      super()
      @receiver    = nil
      @owner       = owner
      @table_name  = owner.table_name
      @block       = block
      @key         = :conditions
      @includes    = []
    end

    ##
    # Sexp Processing Methods
    def process_and(exp)
      joined_expressions 'AND', exp
    end

    def process_or(exp)
      joined_expressions 'OR', exp
    end

    def process_not(exp)
      _, receiver, method, other = *exp.first
      exp.clear
      return translation(receiver, negate(method), other)
    end

    def process_call(exp)
      receiver, method, other = *exp
      exp.clear

      return translation(receiver, method, other)
    end

    def process_lit(exp)
      exp.shift.to_s
    end

    def process_str(exp)
      sanitize exp.shift
    end

    def process_nil(exp)
      'NULL'
    end

    def process_false(exp)
      sanitize 'false'
    end

    def process_true(exp)
      sanitize 'true'
    end

    def process_match3(exp)
      regexp, target = exp.shift.last.inspect.gsub('/',''), process(exp.shift)
      "#{target} REGEXP '#{regexp}'"
    end

    def process_dvar(exp)
      target = exp.shift
      if target == @receiver
        return @table_name
      else
        return value(target.to_s[0..-1])
      end
    end

    def process_ivar(exp)
      value(exp.shift.to_s[0..-1])
    end

    def process_lvar(exp)
      value(exp.shift.to_s)
    end

    def process_vcall(exp)
      value(exp.shift.to_s)
    end

    def process_gvar(exp)
      value(exp.shift.to_s)
    end

    def process_attrasgn(exp)
      exp.clear
      raise "Assignment not supported.  Maybe you meant ==?"
    end

    ##
    #  Processor helper methods
    def joined_expressions(with, exp)
      clauses = []
      while clause = exp.shift
        clauses << clause
      end
      return "(" + clauses.map { |c| process(c) }.join(" #{with} ") + ")"
    end

    def value(variable)
      sanitize eval(variable, @block)
    end

    def negate(method)
      case method
      when :== 
        '<>'
      when :=~
        '!~'
      else 
        raise "Not implemented: #{method}"
      end
    end

    def translation(receiver, method, other)
      case method.to_s
      when '=='
        "#{process(receiver)} = #{process(other)}"
      when '<>', '>', '<'
        "#{process(receiver)} #{method} #{process(other)}"
      when 'include?'
        "#{process(other)} IN (#{process(receiver)})"
      when '=~'
        "#{process(receiver)} LIKE #{process(other)}"
      when '!~'
        "#{process(receiver)} NOT LIKE #{process(other)}"
      else
        build_condition(receiver, method, other)
      end
    end

    def build_condition(receiver, method, other)
      if receiver.first == :call && receiver[1].last == @receiver
        if reflection = @owner.reflections[receiver.last]
          @includes << reflection.name unless @includes.include? reflection.name
          "#{reflection.table_name}.#{method}"
        else
          raise "No reflection `#{receiver.last}' found on #{@owner}"
        end
      else
        "#{process(receiver)}.`#{method}` #{process(other)}"
      end
    end
  end
end
