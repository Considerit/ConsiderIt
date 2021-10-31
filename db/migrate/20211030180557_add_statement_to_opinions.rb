class AddStatementToOpinions < ActiveRecord::Migration[5.2]
  def change
    add_reference :opinions, :statement, polymorphic: true
    ActiveRecord::Base.connection.execute("UPDATE opinions SET statement_type='Proposal', statement_id=proposal_id WHERE statement_type is NULL")
    drop_column :opinions, :proposal_id
  end
end
