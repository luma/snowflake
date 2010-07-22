module Snowflake
  module Model

    # +model+ is extending Node::Model
    # @api private
    def self.extended(model)
      self.descendants << model

      # @todo setup descendants for +model+
      model.instance_variable_set :@descendants, self.descendants

      # @todo include and extend +model+ as necessary
      self.extensions.each { |extension| model.extend extension }
      self.inclusions.each { |inclusion| model.send(:include, inclusion)  }
    end

    # @todo inherited
    def inherited(model)
      self.descendants << model

      # @todo setup descendants for +model+
      model.instance_variable_set :@descendants, self.descendants
      
      # @todo includes and extends
    end

    # Retrieves the list of all descendants of this Node
    #
    # @return [Array]
    #   the list of descendants
    #
    # @api public
    attr_reader :descendants

    # Retrieves the list of all descendants of this Element
    #
    # @return [Array]
    #   the list of descendants
    #
    # @api public
    def self.descendants
      @descendants ||= ::Set.new
    end

    def self.inclusions
      @inclusions ||= ::Set.new
    end

    def self.add_inclusions(*new_inclusions)
      inclusions.merge new_inclusions

      # Add the inclusion to existing descendants
      descendants.each do |model|
        new_inclusions.each { |inclusion| model.send :include, inclusion }
      end
    end
    
    def self.extensions
      @extensions ||= ::Set.new
    end
    
    def self.add_extensions(*new_extensions)
      extensions.merge new_extensions
      
      descendants.each do |model|
        new_extensions.each { |extension| model.extend extension }
      end
    end

    # The list of restricted attribute names. This list could be huge, we just specify
    # several of the most damaging ones here and leave the rest to common sense...which
    # could be a terrible error.
    #
    # @return [Array<Symbol>]
    #     An array of Symbols representing restricted attribute names.
    #
    # @api semi-public
    def self.restricted_names
      @restricted_names ||= [:key, :class, :send, :inspect]
    end

    # Indicates whether +name+ is a restricted Attribute name
    #
    # @param [Symbol, #to_sym] name
    #   The Attribute name to test.
    #
    # @return [Boolean]
    #   True if +name+ is a restricted Attribute name, false otherwise.
    #
    # @api semi-public
    def self.restricted_name?(name)
      restricted_names.include?(name.to_sym)
    end

    # Add a name to the list of restricted Attribute names.
    #
    # @param [Symbol, #to_sym] name
    #   The name to add.
    #
    # @api semi-public
    def self.register_restricted_name(name)
      restricted_names << name.to_sym
    end
  end # module Model
end # module Snowflake