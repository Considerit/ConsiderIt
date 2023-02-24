require 'yaml'

def recursive_symbolize_keys! hash
  hash.symbolize_keys!
  hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
end

def load_local_environment()
  local_config = YAML.load_file "config/local_environment.yml"

  if defined?(local_config.symbolize_keys!)
    recursive_symbolize_keys! local_config
    if Rails.env == 'test'
      return local_config[:test]
    else
      return local_config[:default]
    end
  else 
    if Rails.env = 'test'
      return local_config["test"]
    else 
      return local_config["default"]
    end
  end
end

APP_CONFIG = load_local_environment()
