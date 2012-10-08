require 'rails/generators'
require 'rails/generators/migration'

module Assessable
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def self.next_migration_number(path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end

    def create_assessable_table
      migration_template "create_assessments_tables.rb", "db/migrate/create_assessments_tables.rb"
    end
  end
end