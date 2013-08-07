class Assessable::Claim < ActiveRecord::Base

  belongs_to :assessment, :class_name => 'Assessable::Assessment'
  
  acts_as_tenant :account

  scope :public_fields, select( [:id, :verdict, :claim_restatement, :result])

  #TODO: sanitize before_validation
  #self.text = Sanitize.clean(self.text, Sanitize::Config::RELAXED)

  def self.build_from(obj, user_id, status)
    c = self.new
    c.assessable_id = obj.id 
    c.assessable_type = obj.class.name 
    c
  end

  def root_object
    assessable_type.constantize.find(assessable_id)
  end

  def self.format_verdict(verdict)
    if verdict == 2
      'Accurate'
    elsif verdict == 1
      'Unverifiable'
    elsif verdict == 0
      'Questionable'
    elsif verdict == -1
      'No checkable claims'
    else
      '-'
    end
  end

  def self.translate(verdict)
    if verdict == 'accurate'
      2
    elsif verdict == 'unverifiable'
      1
    else
      0
    end
  end

end
