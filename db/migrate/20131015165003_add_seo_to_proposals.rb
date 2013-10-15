class AddSeoToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :seo_title, :string
    add_column :proposals, :seo_description, :string
    add_column :proposals, :seo_keywords, :string
  end
end
