class Thank < ActiveRecord::Base
  belongs_to :thankable, :polymorphic=>true
  belongs_to :user  
  acts_as_tenant :account

  validates_uniqueness_of :user_id, :scope => [:account_id, :thankable_type, :thankable_id]

  scope :public_fields, -> {select([:created_at, :id, :user_id, :thankable_id, :thankable_type])}


  def self.build_from(obj, user_id, status)
    c = self.new
    c.thankable_id = obj.id 
    c.thankable_type = obj.class.name 
    c.user_id = user_id
    c
  end

  def root_object
    thankable_type.constantize.find(thankable_id)
  end

end
