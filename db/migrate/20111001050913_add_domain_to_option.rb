class AddDomainToOption < ActiveRecord::Migration
  def self.up
    add_column :options, :domain, :string
    add_column :options, :domain_short, :string
  end

  def self.down
    remove_column :options, :domain
    remove_column :options, :domain_short
  end
end
