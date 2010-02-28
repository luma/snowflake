# This is nicked from the awesome DataMapper (http://datamapper.org/) project. This module encapsulates what is effectively a very tidy way
# of using the Decorator design pattern in Ruby.
#
# Usage:
#
# class ExtraFeature
#   extend DataMapper::Chainable
#   def decoratable_method
#     puts "Awesome Stuff Happens Here!"
#     super
#   end
# end
#
# class Example
#   extend DataMapper::Chainable
#   chainable do
#     def decoratable_method
#       puts "Base Method"
#    end
#   end
#
#   include ExtraFeature
# end
#
# example = Example.new
# example.decoratable_method
# => "Base Method"
# => "Awesome Stuff Happens Here!"
#

module DataMapper
  module Chainable
    # @api private
    def chainable(&block)
      mod = Module.new(&block)
      include mod
      mod
    end

    # @api private
    def extendable(&block)
      mod = Module.new(&block)
      extend mod
      mod
    end
  end # module Chainable
end # module DataMapper
