module Snowflake
  module Element
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
      
    end # module Model
  end # module Element
end # module Snowflake