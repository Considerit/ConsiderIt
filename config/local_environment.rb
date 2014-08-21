require 'yaml'

def recursive_symbolize_keys! hash
  hash.symbolize_keys!
  hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
end

def load_local_environment()
  local_config = YAML.load_file "config/local_environment.yml"
  recursive_symbolize_keys! local_config
  return local_config[:default]
end

APP_CONFIG = load_local_environment()
