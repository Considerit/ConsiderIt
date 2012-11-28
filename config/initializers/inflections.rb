# encoding: utf-8

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

APOSTROPHE_CHAR = '’'
String.class_eval do


  def possessive
    self + ('s' == self[-1,1] ? APOSTROPHE_CHAR : APOSTROPHE_CHAR+"s")
  end
end