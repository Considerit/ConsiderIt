class Notification < ActiveRecord::Base

  belongs_to :digest_object, :polymorphic=>true
  belongs_to :event_object, :polymorphic=>true  
  belongs_to :user

  acts_as_tenant :subdomain

  def as_json(options={})
    options[:only] ||= [:digest_object_id, :digest_object_type, :event_object_id, :event_object_type, :event_object_relationship, :event_type, :read_at, :created_at]
    result = super(options)
    result['key'] = "/notification/#{id}"
    result
  end

  def digest_object
    digest_object_type.constantize.find(digest_object_id)
  end

  def event_object
    event_object_type.constantize.find(event_object_id)
  end

  def event
    if event_type == 'content_to_moderate'
      event_type
    else
      "#{event_type.downcase}_#{event_object_type.downcase}"
    end
  end

end
