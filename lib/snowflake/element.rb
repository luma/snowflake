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
    # Provided for ActiveModel compatability.
    #
    # @return [Boolean]
    #   True if this Node has been saved, false otherwise.
    #
    # @api public
    def new_record?
      @_new_node ||= false
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
      !(new_record? || destroyed?)
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

      _run_save_callbacks { new_record?? create : update }
    end
    
    # Saves the Element.
    #
    # If the Element can not be saved the NotPersisted exception is raised.
    #
    # @api public
    def save!
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

      # We need to store this as all the custom attributes will be gone as soon as we 
      # call destroy!
      # @todo the fact that I serialise the element, unserialise it, add a single key/value, and then
      # reserialise it again is awful. There's no defense, but I am very tired and this will be rewritten
      # before being pulled into Master
      deleted_attributes = JSON.parse(to_json).values.first

      _run_destroy_callbacks {
        # Mark it as destroyed
        @_destroyed = true

        if self.class.destroy!( self.key )
          # I'd rather this was decoupled from Element, but I haven't figured out how yet
          # delete_from_indices

          broadcast_event_to_listeners(:destroy, {:attributes => deleted_attributes})
          
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
    
    protected
    
    def broadcast_event_to_listeners(event, payload)
      payload[:event] = event
      send_command(nil, :publish, payload.to_json)
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

          # @todo the fact that I serialise the element, unserialise it, add a single key/value, and then
          # reserialise it again is awful. There's no defense, but I am very tired and this will be rewritten
          # before being pulled into Master
          broadcast_event_to_listeners(:create, {:attributes => JSON.parse(to_json).values.first})

          true
        else
          false
        end
      }
    end

    def update
      _run_update_callbacks {
        if persist == true
          # update_indices

          broadcast_event_to_listeners(:update, {:changes => previous_changes})

          true
        else
          false
        end
      }
    end

    # @todo error checking / handling
    def persist
      @previously_changed = changes

      # Cast the attributes to strings for Redis
      cast_attributes = {}
      deleted_attributes = []

      attributes.each do |name, value|
        proxy = self.class.attributes[name.to_sym]

        # We don't store default values in the data hash. We do need them for filtering
        # though. So we do store them in the indices.
        if proxy.dynamic_default? || ( !value.blank? && value != default_for_attribute(name) )
          cast_attributes[name] = proxy.dump(value)
        elsif attribute_was(name) != value
          # It's been modified to a default value, so we'll nil the currently persisted
          # value
          deleted_attributes << name
        end
      end

      Snowflake.connection.multi do
        # Delete all removed attributes
        deleted_attributes.each do |att|
          send_command(nil, :hdel, att)
        end
        
        # Save all attributes. Note we save the hash even if it's empty, that was we can
        # tell the difference between an Element with all empty (default) values, and one
        # that doesn't even exist (nil).
        send_command(nil, :hmset, *cast_attributes.to_a.flatten)
      end

      # @todo check errors

      reset!
      true  
    end
  end # module Element
end # module Snowflake

