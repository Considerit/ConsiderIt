module ActiveRecord
  module Acts
    module Versioned
      def acts_as_paranoid_versioned(options = {})
        acts_as_paranoid
        acts_as_versioned options

        # Override the destroy method. We want deleted records to end up in the versioned table,
        # not in the non-versioned table.
        self.class_eval do
          def destroy()
            transaction {
              # call the acts_as_paranoid delete function
              self.class.delete_all(:id => self.id)

              # get the 'deleted' object
              tmp = self.class.unscoped.find(id)

              # run it through the equivalent of acts_as_versioned's
              # save_version(). We used to call that function but it is a
              # noop when @saving_version is not set. That only gets done in
              # a protected function set_new_version(). Easier to just
              # replicate the meat of the save_version() function here.
              rev = tmp.class.versioned_class.new
              clone_versioned_model(tmp, rev)
              rev.send("#{tmp.class.version_column}=", send(tmp.class.version_column))
              rev.send("#{tmp.class.versioned_foreign_key}=", id)
              rev.save

              # and finally really destroy the original
              self.class.delete_all!(:id => self.id)
            }
          end
        end

        # protect the versioned model
        self.versioned_class.class_eval do
          def self.delete_all(conditions = nil); return; end
        end
      end
    end
  end
end
