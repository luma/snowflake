module Snowflake
  module Plugins
    module Indices
      Model.add_extensions self
      
      def self.extended(model)
        model.send(:include, InstanceMethods)
      end

      module InstanceMethods
        protected

        def add_to_indices
          self.class.indices[:all].add( self.key )
          
          previous_changes.each do |key, values|
            if self.class.index_for?( key )
              self.class.indices[key.to_sym].add( self.key, values.last )
            end
          end
        end

        def delete_from_indices
          self.class.indices[:all].delete( self.key )

          previous_changes.each do |key, values|
            if self.class.index_for?( key )
              self.class.indices[key.to_sym].delete( self.key, values.first )
            end
          end
        end

        def update_indices
          previous_changes.each do |key, values|
            if self.class.index_for?( key )
              self.class.indices[key.to_sym].modify( self.key, values.first, values.last )
            end
          end
        end
        
        def update_key_for_indices( old_key )
          Snowflake.connection.multi do
            self.class.indices[:all].delete( old_key )
            self.class.indices[:all].add( self.key )
          
            # Remove all instances of old_key from any index
          
            # Add self.key to any indices
          end
        end
      end # module InstanceMethods

      def index_for?(name)
        indices.include?( name.to_sym )
      end

      def indices
        @indices ||= {
          :all => Index.new( :all, self )
        }
      end
    end # module Indices
  end # module Plugins
end # module Snowflake

=begin

18. Indices: sorted sets of ids?
	18.1. All Elements: %model_name%::indices::all => %model_keys% so product::indices::all => set of product_keys;
	18.2. Marking attributes as indices: attribute :name, String, :index => true, or attribute :name, String, :index => :unique. both would use the form: %model_name%::indices::%index_name%::%index_values% => %set of model keys%.
	18.3. key indices (for relationships)
	18.4. Number indices. %model_name%::indices::%index_name%::%index_values (integers or floats)% => %set of model keys%.
	18.5. Date/Time indices, cast of unix timestamps when saving %model_name%::indices::%index_name%::%index_values (unix timestamps)% => %set of model keys%.
	
=end