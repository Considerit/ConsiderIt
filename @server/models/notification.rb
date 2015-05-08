class Notification < ActiveRecord::Base

  belongs_to :object, :polymorphic=>true
  belongs_to :user

  acts_as_tenant :subdomain

  def as_json(options={})
    options[:only] ||= [:notifier_id, :notifier_type, :event_type, :read_at, :created_at]
    result = super(options)
    result['key'] = "notification/#{id}"
    result
  end

  def root_object
    notifier_type.constantize.find(notifier_id)
  end



end
