# Load the Rails application.
require_relative 'application'




# Define global helper functions

def sanitize_helper(str)
  str = "" if !str
  Loofah.fragment(str).scrub!(:strip).to_s.gsub('&amp;','&')
end

# primarily for sanitizing forum customizations object
def sanitize_json(obj, old=nil)
  if old
    stringified = old.to_s
  else 
    stringified = nil
  end

  if obj.is_a? Hash 
    _sanitize_hash(obj, stringified)
  elsif obj.is_a? Array 
    _sanitize_array(obj, stringified)
  elsif obj.is_a? String
    _sanitize_str(obj, stringified)
  else
    obj
  end 
end

def _sanitize_hash(obj, old)
  sanz = {}
  obj.each do |k,v|
    if v.is_a? Hash
      sanz[k] = _sanitize_hash(v, old)
    elsif v.is_a? Array
      sanz[k] = _sanitize_array(v, old)
    elsif v.is_a? String
      sanz[k] = _sanitize_str(v, old)
    else 
      sanz[k] = v
    end
  end
  sanz
end 

def _sanitize_array(arr, old) 
  sanz = []
  arr.each do |el|
    if el.is_a? Hash
      sanz.push _sanitize_hash(el, old)
    elsif el.is_a? Array 
      sanz.push _sanitize_array(el, old)
    elsif el.is_a? String
      sanz.push _sanitize_str(el, old)
    else 
      sanz.push el      
    end 
  end
  sanz
end

def _sanitize_str(str, old)
  adjusted_str = {:v=>str}.to_s["{:v=>\"".length...-"\"}".length] # matching encodings...ugly, I know

  if old && old.index(adjusted_str) != nil # no change, or previously checked as safe elsewhere
    return str 
  elsif current_user && (current_user.super_admin or current_user.trusted)
    return str
  elsif str.start_with?("#javascript")
    pp '********sanitizing unsafe javascript', str
    return "**sanitized unsafe**#javascrip7#{str["#javascript".length..-1]}"  
  else 
    sanitized_str = sanitize_helper(str)
    if str != sanitized_str
      pp "SANITIZED"
      pp "**old"
      pp old
      pp "**string"
      pp str
      pp "**adjusted"
      pp adjusted_str
    end
    return sanitized_str
  end
end


def sanitize_and_execute_query(query_and_params)
  sanitized_query = ActiveRecord::Base.sanitize_sql_array query_and_params
  ActiveRecord::Base.connection.execute(sanitized_query)
end




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
  key = object_or_key.is_a?(String) ? object_or_key : object_or_key['key']
  
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

def slugify(str)
  slug = str.downcase
    .gsub(/\s+/, '-')           # Replace spaces with -
    .gsub(/[^a-zA-Z0-9_\u3400-\u9FBF\s-]+/, '')       # Remove all non-word chars
    .gsub(/\-\-+/, '-')         # Replace multiple - with single -
    .gsub(/^-+/, '')             # Trim - from start of text
    .gsub(/-+$/, '')             # Trim - from end of text

  if str.length > 0 && (!slug || slug.length == 0)
    return nil 
  end 

  slug
end


# Initialize the rails application
Rails.application.initialize! do |config|
  config.serve_static_files = true    
end

if "irb" == $0
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::Store.logger = Logger.new(STDOUT)
end

# comment this out to restore mysql logging output
ActiveRecord::Base.logger.level = 1

code_revision = `git log --pretty=format:%h -n1`.strip
ENV['RAILS_CACHE_ID'] = code_revision
