# Logs user activities such that we can reconstruct usage & track metrics
# :who # user_id
# :what # the behavior
# :where # the page on which it took place
# :when # when it happened
# :details # additional information

class Log < ActiveRecord::Base
  belongs_to :account
  belongs_to :who, :foreign_key => 'who', :class_name => 'User'
end