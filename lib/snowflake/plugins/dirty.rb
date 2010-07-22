module Snowflake
  module Plugins
    module Validations
#        Model.add_extensions ActiveModel::Validations, self
      Model.add_inclusions self

      # Retrieves all Node attributes that have been modified (i.e. dirty attributes).
      #
      # @return [Hash]
      #     The array of dirty attributes
      #
      # @api public
      def changed_attributes
        @changed_attributes ||= {}
      end

      # Indicates true if any attributes have been modified since the last save.
      #
      # @return [Boolean]
      #     True if changes have been made, false otherwise.
      #
      # @api public
      def changed?
        !changed_attributes.empty?
      end

      # Do any attributes have unsaved changes?
      #   person.changed? # => false
      #   person.name = 'bob'
      #   person.changed? # => true
      alias :dirty? :changed?

      # Indicates false if any attributes have been modified since the last save.
      #
      # @return [Boolean]
      #     True if no changes have been made, false otherwise.
      #
      # @api public          
      def clean?
        changed_attributes.empty?
      end

      # Clear our attribute dirty tracking
      #
      # @api private
      def clean!
        changed_attributes.clear
      end

      # List of attributes with unsaved changes.
      #   person.changed # => []
      #   person.name = 'bob'
      #   person.changed # => ['name']
      def changed
        changed_attributes.keys
      end

      # Map of changed attrs => [original value, new value].
      #   person.changes # => {}
      #   person.name = 'bob'
      #   person.changes # => { 'name' => ['bill', 'bob'] }
      def changes
        changed.inject(HashWithIndifferentAccess.new){ |h, attr| h[attr] = attribute_change(attr); h }
      end

      # Map of attributes that were changed when the model was saved.
      #   person.name # => 'bob'
      #   person.name = 'robert'
      #   person.save
      #   person.previous_changes # => {'name' => ['bob, 'robert']}
      def previous_changes
        @previously_changed ||= {}
      end

      def attribute_changed?(attr)
        changed_attributes.include?(attr)
      end

      # Handle <tt>*_change</tt> for +method_missing+.
      def attribute_change(attr)
        [changed_attributes[attr], __send__(attr)] if attribute_changed?(attr)
      end

      # Handle <tt>*_was</tt> for +method_missing+.
      def attribute_was(attr)
        attribute_changed?(attr) ? changed_attributes[attr] : __send__(attr)
      end

      # Handle <tt>*_will_change!</tt> for +method_missing+.
      def attribute_will_change!(attr)
        begin
          value = __send__(attr)
          value = value.duplicable? ? value.clone : value
        rescue TypeError, NoMethodError
        end

        changed_attributes[attr] = value
      end

      def reset_attribute!(attr)
        __send__("#{attr}=", changed_attributes[attr]) if attribute_changed?(attr)
      end
    end # module Validations
  end # module Plugins
end # module Snowflake