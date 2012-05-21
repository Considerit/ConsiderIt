class AddReflectTables < ActiveRecord::Migration
  def self.up

    create_table :reflect_bullet_revisions do |t|
      t.integer :bullet_id
      t.integer :comment_id
      t.text :text
      t.integer :user_id
      t.boolean :active, :default => true

      t.timestamps
    end

    create_table :reflect_bullets do |t|
      t.integer :comment_id
      t.timestamps
    end
    
    create_table :reflect_response_revisions do |t|
      t.integer :bullet_id
      t.integer :bullet_rev
      t.integer :response_id
      t.text :text
      t.integer :user_id
      t.integer :signal
      t.boolean :active, :default => true
      
      t.timestamps
    end
    
    create_table :reflect_responses do |t|
      t.integer :bullet_id

      t.timestamps
    end
    
    create_table :reflect_highlights do |t|
      t.integer :bullet_id
      t.integer :bullet_rev
      t.string :element_id

      t.timestamps
    end    
                    
  end

  def self.down
    drop_table :reflect_bullet_revisions
    drop_table :reflect_bullets
    drop_table :reflect_response_revisions        
    drop_table :reflect_responses
    drop_table :reflect_highlights
  end
end
