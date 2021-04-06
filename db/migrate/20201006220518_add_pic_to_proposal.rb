class AddPicToProposal < ActiveRecord::Migration[5.2]
  def up
    add_attachment :proposals, :pic
    add_attachment :proposals, :banner
  end

  def down
    remove_attachment :proposals, :pic
    remove_attachment :proposals, :banner
  end


end
