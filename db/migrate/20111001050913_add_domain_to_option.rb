class AddDomainToOption < ActiveRecord::Migration
  def self.up
    add_column :options, :domain, :string
    add_column :options, :domain_short, :string
  end

  def self.down
    drop_column :options, :domain
    drop_column :options, :domain_short
  end
end
