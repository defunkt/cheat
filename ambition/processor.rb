require 'active_record/connection_adapters/abstract/quoting'

module Ambition
  class Processor < SexpProcessor 
    include ActiveRecord::ConnectionAdapters::Quoting

    attr_reader :key, :join_string, :prefix

    def initialize
      super()
      @strict          = false
      @expected        = String
      @auto_shift_type = true
      @warn_on_default = false
      @default_method  = :process_error
    end

    ##
    # Processing methods
    def process_error(exp)
      raise "Missing process method for sexp: #{exp.inspect}"
    end

    def process_proc(exp)
      receiver, body = process(exp.shift), exp.shift
      return process(body)
    end

    def process_dasgn_curr(exp)
      @receiver = exp.shift
      return @receiver.to_s
    end

    def process_array(exp)
      arrayed = exp.map { |m| process(m) }
      exp.clear
      return arrayed.join(', ')
    end

    ##
    # Helper methods
    def to_s
      process(@block.to_sexp).squeeze(' ')
    end

    def sanitize(value)
      case value.to_s
      when 'true'  then '1'
      when 'false' then '0'
      else ActiveRecord::Base.connection.quote(value) rescue quote(value)
      end
    end
  end
end
