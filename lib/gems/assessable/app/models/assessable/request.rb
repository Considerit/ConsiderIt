class Assessable::Request < ActiveRecord::Base

  belongs_to :assessable, :polymorphic=>true
  belongs_to :user
  belongs_to :assessment, :class_name => 'Assessable::Assessment'

  acts_as_tenant(:account)

  def self.build_from(obj, user_id, status)
    c = self.new
    c.assessable_id = obj.id 
    c.assessable_type = obj.class.name 
    c.user_id = user_id
    c
  end

  def root_object
    assessable_type.constantize.find(assessable_id)
  end

end
