##
# Taken from ruby2ruby, Copyright (c) 2006 Ryan Davis under the MIT License
require 'parse_tree'
require 'unique'
require 'sexp_processor'

class Method
  def with_class_and_method_name
    if self.inspect =~ /<Method: (.*)\#(.*)>/ then
      klass = eval $1
      method  = $2.intern
      raise "Couldn't determine class from #{self.inspect}" if klass.nil?
      return yield(klass, method)
    else
      raise "Can't parse signature: #{self.inspect}"
    end
  end

  def to_sexp
    with_class_and_method_name do |klass, method|
      ParseTree.new(false).parse_tree_for_method(klass, method)
    end
  end
end

class Proc
  def to_method
    Unique.send(:define_method, :proc_to_method, self)
    Unique.new.method(:proc_to_method)
  end

  def to_sexp
    body = self.to_method.to_sexp[2][1..-1]
    [:proc, *body]
  end
end
