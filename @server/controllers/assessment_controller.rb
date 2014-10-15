class AssessmentController < ApplicationController  
  respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :errors => [current_user.nil? ? 'not logged in' : 'not authorized']
    }
    render :json => result 
    return
  end

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    authorize! :index, Assessable::Assessment

    assessments = Assessable::Assessment.all.each do |assessment|
      dirty_key "/point/#{assessment.assessable_id}"
      dirty_key "/proposal/#{assessment.root_object().proposal_id}"
    end

    result = { 
      :key => '/dashboard/assessment',
      :assessments => Assessable::Assessment.all,
      :verdicts => Assessable::Verdict.all
    }

    render :json => [result]

  end

  def show
    authorize! :index, Assessable::Assessment

    assessment = Assessable::Assessment.find(params[:id])
    #TODO: authorize against this specific assessment?

    dirty_key "/assessment/#{params[:id]}"
    render :json => []
  end

  def update
    authorize! :index, Assessable::Assessment
    
    fields = ["complete", "reviewable", "notes"]
    updates = params.select{|k,v| fields.include? k}

    assessment = Assessable::Assessment.find(params[:id])
    already_published = assessment.complete

    if params.has_key?('user') && !params['user']
      assessment.user_id = nil
    else
      assessment.user_id = key_id(params['user'])
    end

    assessment.update_attributes! updates

    if assessment.complete
      assessment.update_verdict()
    end

    if !already_published && assessment.complete
      assessment.published_at = Time.now.utc      
      assessment.save

      ActiveSupport::Notifications.instrument("assessment_completed", 
        :assessment => assessment,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    else 
      assessment.save
    end

    dirty_key "/assessment/#{params[:id]}"
    render :json => []
  end

  ### User facing
  # create a new assessment request
  # "/request_assessment/:point_id"

  def create
    authorize! :create, Assessable::Request

    point = Point.find(key_id(params['point']))

    request = {
      'suggestion' => params['suggestion'],
      'user_id' => current_user && current_user.id || nil,
      'account_id' => current_tenant.id,
      'assessable_type' => 'Point',
      'assessable_id' => point.id
    }

    request = Assessable::Request.new request

    assessment = Assessable::Assessment.where(:assessable_type => request['assessable_type'], :assessable_id => request['assessable_id']).first
    if !assessment
      create_attrs = {
        :account_id => current_tenant.id, 
        :assessable_type => request['assessable_type'],
        :assessable_id => request['assessable_id'] }
        
      assessment = Assessable::Assessment.create! create_attrs

      ActiveSupport::Notifications.instrument("new_assessment_request", 
        :assessment => assessment,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    request.assessment = assessment
    request.save

    begin
      assessment.root_object.follow!(current_user, :follow => true, :explicit => false)
    rescue
    end

    original_id = key_id(params[:key])
    result = request.as_json
    result['key'] = "/request/#{request.id}?original_id=#{original_id}"
    remap_key(params[:key], "/request/#{request.id}")

    dirty_key "/comments/#{point.id}"

    render :json => [result, assessment] 
  end


end

ActiveSupport::Notifications.subscribe("new_assessment_request") do |*args|
  data = args.last
  assessment = data[:assessment]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]
  assessable = assessment.root_object

  # send to all users with moderator status
  evaluators = []
  current_tenant.users.where('roles_mask > 0').each do |u|
    if u.has_any_role? :evaluator, :superadmin
      evaluators.push(u)
    end
  end
  evaluators.each do |user|
    AlertMailer.content_to_assess(assessment, user, current_tenant).deliver!
  end

end

ActiveSupport::Notifications.subscribe("assessment_completed") do |*args|
  data = args.last
  assessment = data[:assessment]
  current_tenant = data[:current_tenant]
  mail_options = data[:mail_options]

  assessable = assessment.root_object

  commenters = assessable.comments.select(:user_id).uniq.map {|x| x.user_id }
  includers = assessable.inclusions.select(:user_id).uniq.map {|x| x.user_id }
  requesters = assessment.requests.select(:user_id).uniq.map {|x| x.user_id }

  assessable.follows.where(:follow => true).each do |follow|

    if !follow.user || !follow.user.email || follow.user.email.length == 0
      next

    # if follower is author of point
    elsif follow.user_id == assessable.user_id
      notification_type = 'your point'

    # if follower requested the check
    elsif requesters.include?(follow.user_id)
      notification_type = 'requested by you'
    
    # if follower is a participant in the discussion
    elsif commenters.include? assessable.user_id
      notification_type = 'participant'

    # if follower included the point
    elsif includers.include? follow.user_id
      notification_type = 'included point'
    end

    EventMailer.new_assessment(follow.user, assessable, assessment, mail_options, notification_type).deliver!

  end

end
