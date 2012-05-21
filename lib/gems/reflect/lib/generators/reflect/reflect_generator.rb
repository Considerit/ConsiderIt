require 'rails/generators'
require 'rails/generators/migration'

class ReflectGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_migration_file
    migration_template "create_reflect_tables.rb", "db/migrate/create_reflect_tables.rb"
  end
end