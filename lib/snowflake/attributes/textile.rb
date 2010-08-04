require 'RedCloth'

module Snowflake
  module Attributes
    class Textile < Attribute
      def initialize(node, name, options = {})
        
        options[:restrictions] ||= []

        if options.include?( :simple )
          options.delete(:simple)
          options[:restrictions] = options[:restrictions].concat( [:sanitize_html, :lite_mode] )
        end

        super(node, name, options)
      end

      # Convert +value+ to a String
      def dump(value)
        value.to_s
      end

      # Typecasts +value+ to the correct type for this Attribute.
      #
      # @param [Any] value
      #     The value to convert.
      #
      # @return [RedCloth::TextileDoc, #default]
      #     A typecast version of +value+. Usually a RedCloth::TextileDoc, or the return 
      #     value from #default.
      # 
      # @api semi-public
      def typecast(value)
        if value == nil
          default
        else
          RedCloth.new(value.to_s, @options[:restrictions])
        end
      # rescue NoMethodError => e
      #   raise ArgumentError, "Tried to cast #{value.inspect} to a Textile Attribute. Only values that can be cast to a String (via #to_s) can be assigned to a Textile Attribute."
      end

    end # class String
  end # module Attributes
end # module Snowflake