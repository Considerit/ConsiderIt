class AddScoringToPoints < ActiveRecord::Migration
  def self.up
    
    add_column :points, :num_inclusions, :integer
    add_column :points, :unique_listings, :integer
    
    add_column :points, :score, :float
    
    add_column :points, :attention, :float
    add_column :points, :persuasiveness, :float
    add_column :points, :appeal, :float
    
    (0..6).each do |bucket|
      add_column :points, "score_stance_group_#{bucket}".intern, :float
    end
    
  end

  def self.down
    remove_column :points, :inclusions
    
    remove_column :points, :score
    
    remove_column :points, :attention
    remove_column :points, :persuasiveness
    remove_column :points, :appeal
    
    (0..6).each do |bucket|
      remove_column :points, "score_stance_group-#{bucket}".intern
    end

  end
end
