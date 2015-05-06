class Assessment < ActiveRecord::Base
  include Notifier
  
  belongs_to :user

  belongs_to :assessable, :polymorphic => true

  #These would have to be revised if more than just Points could be assessed
  belongs_to :point, :foreign_key => 'assessable_id'
  has_one :proposal, :through => :point
  ###
  
  has_many :claims, :class_name => 'Assessable::Claim'
  has_many :requests, :class_name => 'Assessable::Request'
  belongs_to :verdict, :class_name => 'Assessable::Verdict'
  
  scope :completed, -> {where( :complete => true )}

  acts_as_tenant :subdomain

  def self.all_for_subdomain
    current_subdomain = Thread.current[:subdomain]

    assessments = current_subdomain.assessments

    assessments.each do |assessment|
      dirty_key "/point/#{assessment.assessable_id}"
      dirty_key "/proposal/#{assessment.root_object().proposal_id}"
    end

    result = { 
      :key => '/page/dashboard/assessment',
      :assessments => assessments,
      :verdicts => Assessable::Verdict.all
    }

  end

  def as_json(options={})
    result = super(options)
    make_key(result, 'assessment')


    result['point'] = "/point/#{assessable_id}"
    result['verdict'] = "verdict/#{verdict_id}"
    result['requests'] = requests
    result['claims'] = claims
    stubify_field(result, 'user')
    result
  end


  def root_object
    assessable_type.constantize.find(assessable_id)
  end

  def update_verdict
    if self.claims.count == 0
      self.verdict_id = -1
    else
      self.verdict_id = self.claims.map{|x| x.verdict_id}.compact.min
    end

  end

end