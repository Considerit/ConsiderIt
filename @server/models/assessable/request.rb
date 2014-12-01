class Assessable::Request < ActiveRecord::Base

  belongs_to :user
  belongs_to :assessment
  belongs_to :assessable, :polymorphic => true
  acts_as_tenant :subdomain

  before_save do
    self.suggestion = self.suggestion.sanitize if self.suggestion
  end

  def as_json(options={})
    result = super(options)
    make_key(result, 'request')
    result['user'] = "/user/#{user_id}"
    result['point'] = "/point/#{assessable_id}"
    result
  end

end
