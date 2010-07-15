module Snowflake
  module Element        
    def initialize(attributes = {})
      @_new_node = true
      @_destroyed = false
      self.key = attributes.delete(:key)
      self.attributes = attributes
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

    # Save the Node to the DB.
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

    # Deletes the Node
    #
    # @return [Boolean]
    #     True for sucess, false otherise.
    #
    # @api public
    def destroy!
      # Nothing persisted? Nothing to delete, we're done.
      return true unless persisted?

      _run_destroy_callbacks {
        # Mark it as destroyed
        @_destroyed = true

        # Hmmm, if the key has been changed we're gonna assume they mean to delete the new
        # key, but as the record is dirty, and it always when @_key != self.key, deleting
        # the new key will do nothing as we haven't saved anything under the new key yet.
        return true unless @_key == self.key

        self.class.destroy!( @_key )
      }

      true
    end

    # Reset dirty tracking, current key, and saved state.
    #
    # @api semi-public
    def reset!
      @_key = self.key
      clean!
    end

    # Returns a string representing the object's key suitable for use in URLs
    # or nil if #persisted? is false.
    #
    # @return [String]
    #     The url path component.
    #
    # @api public
    def to_param
      self.key
    end

    # Retrieve the value of the key property for this Node, this is provided for 
    # ActiveModel compatability and it differs slightly from #key as it returns nil if
    # #persisted? is false.
    #
    # @return [#to_s] The Id value
    #
    # @api public
    def to_key
      if persisted?
        self.key
      else
        nil
      end
    end

    # @api private
    def send_command(path_suffix, command, *args, &block)
      unless path_suffix == nil
        Snowflake.connection.send(command.to_sym, *args.dup.unshift( redis_key(path_suffix.to_s) ), &block)
      else
        Snowflake.connection.send(command.to_sym, *args.dup.unshift( redis_key ), &block)
      end
    end

  #    protected

    # @todo I'm not sure this should be public
    def redis_key(*segments)
      self.class.redis_key(*segments.unshift(self.key))
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
      # @todo I'm using MULTI as if it's a transaction, except it isn't, as if one command fails 
      # all commands follow it will execute (http://code.google.com/p/redis/wiki/MultiExecCommand). This
      # is currently an unresolved issue, mainly 'cause I don't know how yet...
      Snowflake.connection.multi do
        # If the key has been changed then shift every property to the new key
        if persisted? && @_key != self.key
          unless _run_rename_callbacks { self.class.rename(@_key, self.key) }
            # @todo the error
          end
        end

        # Cast the attributes to strings for Redis
        cast_attributes = {}
        attributes.each do |key, value|
          proxy = self.class.attributes[key]

          cast_attributes[key] = proxy != nil ? proxy.dump(value) : Attribute.default_typecast(value)
        end

        # Save all attributes
#        debugger
        send_command(nil, :hmset, *cast_attributes.to_a.flatten)
        # @todo error handling
      end

      # @todo refactor
      reset!
      true  
    end
  end # module Element
end # module Snowflake

