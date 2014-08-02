class Assessable::Request < ActiveRecord::Base

  belongs_to :user
  belongs_to :assessment, :class_name => 'Assessable::Assessment'
  belongs_to :assessable, :polymorphic => true
  acts_as_tenant :account

  before_save do
    self.suggestion = self.suggestion.sanitize if self.suggestion
  end


end
