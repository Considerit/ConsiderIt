class Assessable::Claim < ActiveRecord::Base
  
  belongs_to :assessment, :class_name => 'Assessable::Assessment'
  acts_as_tenant :account

  belongs_to :creator_user, :foreign_key => 'creator', :class_name => 'User'
  belongs_to :approver_user, :foreign_key => 'approver', :class_name => 'User'

  belongs_to :verdict, :class_name => 'Assessable::Verdict'

  #TODO: sanitize before_validation
  #self.text = Sanitize.clean(self.text, Sanitize::Config::RELAXED)

  def as_json(options={})
    result = super(options)
    result['key'] = "claim/#{id}"
    result['point'] = "/point/#{assessment.assessable_id}"    
    result['verdict'] = "verdict/#{verdict_id}"    
    result
  end


end
