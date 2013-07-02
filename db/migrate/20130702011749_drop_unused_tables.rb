class DropUnusedTables < ActiveRecord::Migration
  def change
    drop_table :reflect_bullet_revisions
    drop_table :reflect_highlights
    drop_table :reflect_bullets
    drop_table :reflect_response_revisions
    drop_table :reflect_responses 
    drop_table :point_similarities            
    drop_table :domain_maps            
    drop_table :domains
    drop_table :taggings
    drop_table :tags
    drop_table :theme_directreps            

  end
end
