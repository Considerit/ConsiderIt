class MakeEverythingTenanted < ActiveRecord::Migration
  def change

    #add_index :proposals, :account_id
    #add_index :points, :account_id
    #add_index :positions, :account_id

    tables = [:reflect_bullets, :reflect_bullet_revisions, :reflect_highlights, :reflect_responses, :reflect_response_revisions,
              :comments, :domains, :domain_maps, :inclusions, :point_links, :point_listings, :users]

    tables.each do |tbl|
      add_column tbl, :account_id, :integer
      add_index tbl, :account_id
    end

  end
end
