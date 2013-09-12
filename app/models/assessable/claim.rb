class Assessable::Claim < ActiveRecord::Base

  belongs_to :assessment, :class_name => 'Assessable::Assessment'
  acts_as_tenant :account

  belongs_to :creator_user, :foreign_key => 'creator', :class_name => 'User'
  belongs_to :approver_user, :foreign_key => 'approver', :class_name => 'User'

  scope :public_fields, select( [:id, :verdict_id, :claim_restatement, :result, :assessment_id, :approver, :creator])

  belongs_to :verdict, :class_name => 'Assessable::Verdict'

  #TODO: sanitize before_validation
  #self.text = Sanitize.clean(self.text, Sanitize::Config::RELAXED)


end
