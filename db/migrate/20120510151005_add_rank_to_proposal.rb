class AddRankToProposal < ActiveRecord::Migration
  def change

    add_column :proposals, :score, :float

    add_column :proposals, :activity, :float
    add_column :proposals, :persuasiveness, :float
    add_column :proposals, :devisiveness, :float

    add_column :proposals, :num_points, :integer
    add_column :proposals, :num_pros, :integer
    add_column :proposals, :num_cons, :integer
    add_column :proposals, :num_comments, :integer
    add_column :proposals, :num_inclusions, :integer

    add_column :proposals, :num_perspectives, :integer
    add_column :proposals, :num_supporters, :integer
    add_column :proposals, :num_opposers, :integer

    add_column :proposals, :num_views, :integer

  end
end
