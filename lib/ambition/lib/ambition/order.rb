module Ambition
  module Order
    def sort_by(&block)
      query_context.add OrderProcessor.new(table_name, block)
    end
  end

  class OrderProcessor < Processor 
    def initialize(table_name, block)
      super()
      @receiver    = nil
      @table_name  = table_name
      @block       = block
      @key         = :order
    end

    ##
    # Sexp Processing Methods
    def process_call(exp)
      receiver, method, other = *exp
      exp.clear

      translation(receiver, method, other)
    end

    def process_vcall(exp)
      if (method = exp.shift) == :rand
        'RAND()'
      else
        raise "Not implemented: :vcall for #{method}"
      end
    end

    def process_masgn(exp)
      exp.clear
      ''
    end

    ##
    # Helpers!
    def translation(receiver, method, other)
      case method
      when :-@
        "#{process(receiver)} DESC"
      when :__send__
        "#{@table_name}.#{eval('to_s', @block)}"
      else
        "#{@table_name}.#{method}"
      end
    end
  end
end
