# Load the rails application
require File.expand_path('../application', __FILE__)

# Define global helper functions

def stubify_field(hash, name)
  id = hash[name + '_id']
  #hash[name] = (id and { :key => "/#{name}/#{id}?stub" })
  hash[name] = (id && "/#{name}/#{id}")
  hash.delete(name + '_id')
end

def make_key(hash, name)
  id = hash["id"]
  hash['key'] = (id && "/#{name}/#{id}")

  # This is disabled for the legacy dash.  Turn back on when we're free of it.
  # hash.delete('id')
end

def jsonify_objects(objects, name, reference_names=[], delete_names=[], parse_names=[])
  objects.map {|object|
    object = object.as_json
    make_key(object, name)
    reference_names.each {|n| stubify_field(object, n)}
    delete_names.each    {|n| object.delete(n)}
    parse_names.each     {|n| object[n] = JSON.parse(object[n])}
    object
  }
end

def key_id(object_or_key, session=nil)
  # puts("Key_id called for #{object_or_key}")

  # Make it into a key
  key = object_or_key.is_a?(Hash) ? object_or_key['key'] : object_or_key

  # # Translate from '/new/', and similar things
  # if session and session[:remapped_keys] and session[:remapped_keys][key]
  #   key = session[:remapped_keys][key]
  # end
  
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

def remap_key(old_key, new_key)
#   Thread.current[:remapped_keys][old_key] = new_key
end

def current_user
  return nil if !Thread.current[:current_user_id2]

  if !Thread.current[:current_user2]
    # Well then, time to load the user OBJECT from the database for this id.
    Thread.current[:current_user2] = User.find_by_id(Thread.current[:current_user_id2])
  end
  Thread.current[:current_user2]
end


# Initialize the rails application
ConsiderIt::Application.initialize! do |config|
  config.serve_static_assets = true    
end

if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
end

ActiveRecord::Base.logger.level = 1

code_revision = `git log --pretty=format:%h -n1`.strip
ENV['RAILS_CACHE_ID'] = code_revision
