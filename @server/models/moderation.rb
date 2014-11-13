class Moderation < ActiveRecord::Base

  class_attribute :STATUSES
  self.STATUSES = %w(fails passes)

  belongs_to :moderatable, :polymorphic=>true
  belongs_to :user
  
  acts_as_tenant(:account)

  class_attribute :my_public_fields
  self.my_public_fields = [:user_id, :id, :status, :moderatable_id, :moderatable_type, :updated_at, :updated_since_last_evaluation, :notification_sent]


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

  def as_json(options={})
    options[:only] ||= Moderation.my_public_fields
    result = super(options)

    result['moderatable'] = "/#{moderatable_type.downcase}/#{moderatable_id}"
    make_key result, 'moderation'  
    stubify_field result, 'user'
    result

  end

end
