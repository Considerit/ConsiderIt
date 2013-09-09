class Moderation < ActiveRecord::Base
  class_attribute :classes_to_moderate
  self.classes_to_moderate = [Point, Comment, Proposal]

  class_attribute :STATUSES
  self.STATUSES = %w(fails passes)

  belongs_to :moderatable, :polymorphic=>true
  belongs_to :user
  
  acts_as_tenant(:account)

  def self.build_from(obj, user_id, status)
    c = self.new
    c.moderatable_id = obj.id 
    c.moderatable_type = obj.class.name 
    c.status = status
    c.user_id = user_id
    c
  end

  def root_object
    moderatable_type.constantize.find(moderatable_id)
  end

end
