module Yamler
  class Template
    def optional_yaml(path)
      path = File.extname(path) == '' ? "#{path}.yml" : path
      require_yaml(path) if File.exists?(path)
    end
  end
end

require 'yamler'

class Configuration
  def self.load_yaml(path, opts = {})
    yml = Yamler.load(path)

    config = build_inheritance_chain yml, opts[:hash].to_s, opts[:inherit].to_s unless opts[:hash].nil? or opts[:inherit].nil?
    apply_overrides yml, config, opts[:override_with].to_s unless opts[:override_with].nil?

    config
  end

  def self.build_inheritance_chain(everything, selector, inheritance_attr)
    selection = everything[selector]

    if not selection[inheritance_attr].nil?
      puts "Settings for '#{selector}' inherit '#{selection[inheritance_attr]}' via attribute '#{inheritance_attr}'"

      inherited = build_inheritance_chain everything, selection[inheritance_attr], inheritance_attr
      selection = inherited.recursive_merge(selection)
      selection.delete(inheritance_attr)
    end

    selection
  end

  def self.apply_overrides(everything, config, selector)
    overrides = everything[selector] 

    return if overrides.nil?

    puts "Applying configuration overrides from #{selector}"
    config.recursive_merge(overrides)
  end
end

class Hash
  def recursive_merge(h)
    self.merge!(h) do |key, _old, _new|
      if _old.class == Hash
        _old.recursive_merge(_new)
      else
        _new
      end
    end
  end
end

def recursive_symbolize_keys! hash
  hash.symbolize_keys!
  hash.values.select{|v| v.is_a? Hash}.each{|h| recursive_symbolize_keys!(h)}
end

APP_CONFIG = Configuration.load_yaml "config/local_environment.yml", :hash => Rails.env, :inherit => :default_to

recursive_symbolize_keys! APP_CONFIG