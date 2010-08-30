require 'rubygems'
require 'pp'
require 'ruby-debug'

class Person  
  class << self
    def all(&block)
      Query.new(&block).eval
    end
  end
end

class Query  
  attr_reader :results

  def initialize(&block)
    @block = block
    @results = []
  end

  def eval
    context = QueryContext.new(&@block)
    @results = []

    (context.events.length / 2).times do |i|
      step = 2*i
      @results << Operation.new( context.events[step+1][0], context.events[step][0], context.events[step+1][1] )
    end

    self
  end
end

class Operation
  attr_reader :name, :operand1, :operand2
  def initialize(name, operand1, operand2)
    @name, @operand1, @operand2 = name, operand1, operand2
  end
  
  def to_s
    "#{@operand1.inspect} #{@name} #{@operand2.inspect}"
  end
end

class QueryContext
  attr_reader :attributes, :events

  def initialize(*attributes, &block)
    @attributes = attributes
    @events = []
    instance_eval(&block)
  end
  
  def ==(other)
    @events << [:'==', other]
  end
  
  def !=(other)
    @events << [:'!=', other]
  end

  def method_missing(method, *args, &block)
    @events << [method, *args]
    self
  end
end

query = Person.all { name != 'bob' && mood == 'awesome' && age > 25  && age <= 60 }
pp query.results