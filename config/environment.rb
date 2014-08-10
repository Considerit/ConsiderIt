# Load the rails application
require File.expand_path('../application', __FILE__)

# Define global helper functions

def stubify_field(hash, name)
  id = hash[name + '_id']
  #hash[name] = (id and { :key => "/#{name}/#{id}?stub" })
  hash[name] = (id and "/#{name}/#{id}")
  hash.delete(name + '_id')
end
def make_key(hash, name)
  id = hash["id"]
  hash['key'] = (id and "/#{name}/#{id}")
  hash.delete('id')
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

def key_id(key)
  key.split('/')[-1].to_i
end

# Initialize the rails application
ConsiderIt::Application.initialize! do |config|
  config.serve_static_assets = true    
end

if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
end

code_revision = `git log --pretty=format:%h -n1`.strip
ENV['RAILS_CACHE_ID'] = code_revision
