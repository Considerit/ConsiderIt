class CreateDomains < ActiveRecord::Migration
  def self.up
    create_table :domains do |t|
      t.integer :identifier
      t.string :name
    end
    add_index :domains, :identifier    
  end

  def self.down
    drop_table :domains
  end
end
