module Snowflake
  module Element        
    def initialize(attributes = {})
      @_new_node = true
      @_destroyed = false

      update_key_with_renaming( attributes.delete(:key) )
      self.attributes = attributes

      _run_initialize_callbacks
    end

    # @api public
    def ==(other)
      other.is_a?(self.class) && self.key == other.key
    end

    # @api public
    def eql?(other)
      self == other
    end

    # @api public
    def equal?(other)
      object_id === other.object_id
    end

    # Comparing objects
    def <=>(other)
      self.key <=> other.key
    end

    # Provides basic compatability with ActiveModel
    def to_model
      self
    end

    # Indicates whether this Node has been saved yet.
    #
    # @return [Boolean]
    #   True if this Node has been saved, false otherwise.
    #
    # @api public
    def new?
      @_new_node ||= false
    end

    # Indicates whether this Node has been saved yet. Synonym of #new?
    #
    # Provided for ActiveModel compatability.
    #
    # @return [Boolean]
    #   True if this Node has been saved, false otherwise.
    #
    # @api public
    def new_record?
      self.new?
    end

    # Indicates whether this Node has been destroyed
    #
    # @api public
    def destroyed?
      @_destroyed ||= false
    end

    # Returns if the record is persisted, i.e. it's not a new record and it was not destroyed.
    #
    # @api public
    def persisted?
      !(new? || destroyed?)
    end

    # Save the Element
    #
    # @return [Boolean]
    #     True if the save was successful, false otherwise.
    #
    # @api public
    def save
      # Bail, if there's nothing to do anyways
      return true unless dirty?

      # Bail, if there's validation errors.
      return false unless valid?

      _run_save_callbacks { new?? create : update }
    end
    
    # Saves the Element.
    #
    # If the Element can not be saved the NotPersisted exception is raised.
    #
    # @api public
    def save!(*)
      save || raise(NotPersisted)
    end

    # Deletes the Node
    #
    # @return [Boolean]
    #     True for sucess, false otherise.
    #
    # @api public
    def destroy
      # Nothing persisted? Nothing to delete, we're done.
      return true unless persisted?

      _run_destroy_callbacks {
        # Mark it as destroyed
        @_destroyed = true

        if self.class.destroy!( self.key )
          # I'd rather this was decoupled from Element, but I haven't figured out how yet
          delete_from_indices
          
          true
        else
          false
        end
      }

      true
    end

    # Reset dirty tracking, current key, and saved state.
    #
    # @api semi-public
    def reset!
      clean!
    end

    # Retrieve the value of the key property for this Node, this is provided for 
    # ActiveModel compatability and it differs slightly from #key as it returns nil if
    # #persisted? is false.
    #
    # @return [Array] The Id value
    #
    # @api public
    def to_key
      if persisted?
        [self.key]
      else
        nil
      end
    end

    # Returns a string representing the object's key suitable for use in URLs
    # or nil if #persisted? is false.
    #
    # @return [String]
    #     The url path component.
    #
    # @api public
    def to_param
      to_key ? to_key.join('-') : nil
    end

    # @api private
    def send_command(path_suffix, command, *args, &block)
      unless path_suffix == nil
        Snowflake.connection.send(command.to_sym, *args.dup.unshift( key_for(path_suffix.to_s) ), &block)
      else
        Snowflake.connection.send(command.to_sym, *args.dup.unshift( key_for ), &block)
      end
    end

  #    protected

    # @todo I'm not sure this should be public
    def key_for(*segments)
      Keys.key_for( self.class, *segments.unshift( self.key ) )
    end

    # @todo I'm not sure this should be public
    def meta_key_for(*segments)
      Keys.meta_key_for( self.class, *segments.unshift( self.key ) )
    end

    private

    def create
      # We shouldn't save the Node if a Node with the same key already exists
      if self.class.exists?(self.key)
        errors.add(self.class.key, "A #{self.class.to_s} with a #{self.class.key.to_s} key of #{self.key} already exists, the Node key must be unique.")
        return false
      end

      _run_create_callbacks {
        if persist == true
          @_new_node = false
          
          # I'd rather this was decoupled from Element, but I haven't figured out how yet
          add_to_indices
          
          true
        else
          false
        end
      }
    end

    def update
      _run_update_callbacks { persist }
    end

    # @todo error checking / handling
    def persist
      @previously_changed = changes

      # Cast the attributes to strings for Redis
      cast_attributes = {}
      attributes.each do |key, value|
        proxy = self.class.attributes[key.to_sym]

        unless proxy.default?(value)
          cast_attributes[key] = proxy.dump(value)
        end
      end

      # Save all attributes
      send_command(nil, :hmset, *cast_attributes.to_a.flatten)
      # @todo error handling

      # @todo refactor
      reset!
      true  
    end
  end # module Element
end # module Snowflake

