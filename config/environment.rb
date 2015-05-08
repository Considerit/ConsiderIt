# Load the rails application
require File.expand_path('../application', __FILE__)

# Define global helper functions

def stubify_field(hash, name)
  id = hash[name + '_id']
  hash[name] = (id && "/#{name}/#{id}")
  hash.delete(name + '_id')
end

def make_key(hash, name)
  id = hash["id"]
  hash['key'] = hash['key'] || (id && "/#{name}/#{id}")
end

def key_id(object_or_key)
  # puts("Key_id called for #{object_or_key}")

  # Make it into a key
  key = object_or_key.is_a?(Hash) ? object_or_key['key'] : object_or_key
  
  # Grab the id out
  result = key.split('/')[-1].to_i
  # puts("Returning id #{result}")
  result
end

def dirty_key(key)
  if Thread.current[:dirtied_keys]
    Thread.current[:dirtied_keys][key] = 1
  end
end

def current_user
  return nil if !Thread.current[:current_user_id]

  if !Thread.current[:current_user]
    # Well then, time to load the user OBJECT from the database for this id.
    Thread.current[:current_user] = User.find_by_id(Thread.current[:current_user_id])
  end
  Thread.current[:current_user]
end

def current_subdomain
  Thread.current[:subdomain]
end


# Initialize the rails application
ConsiderIt::Application.initialize! do |config|
  config.serve_static_files = true    
end

if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
end

ActiveRecord::Base.logger.level = 1

code_revision = `git log --pretty=format:%h -n1`.strip
ENV['RAILS_CACHE_ID'] = code_revision
