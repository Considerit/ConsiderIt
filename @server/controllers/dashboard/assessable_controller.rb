class Dashboard::AssessableController < Dashboard::DashboardController

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    authorize! :index, Assessable::Assessment

    assessments = Assessable::Assessment.order(:complete)
    assessable_ids = assessments.map{ |assessment| assessment.assessable_id }.compact
    assessable_objects = Point.where("id in (?)", assessable_ids).public_fields.to_a
    root_objects_ids = assessable_objects.map{ |assessed| assessed.proposal_id }.compact
    root_objects = Proposal.where("id in (?)", root_objects_ids).public_fields.to_a

    result = { 
      :verdicts => Assessable::Verdict.all,
      :assessments => assessments,
      :assessable_objects => assessable_objects,
      :admin_template => params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil,
      :root_objects => root_objects
    }

    if request.xhr?
      render :json => result 
    else
      render "layouts/dash", :layout => false 
    end

  end

  def edit
    authorize! :index, Assessable::Assessment

    assessment = Assessable::Assessment.find(params[:id])
    root_object = assessment.proposal 
    
    result = {
      :verdicts => Assessable::Verdict.all,
      :assessment => assessment,
      :requests => assessment.requests,
      :claims => assessment.claims,
      :all_claims => root_object.claims,
      :assessable_obj => assessment.root_object, 
      :admin_template => params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil,      
      :root_object => root_object
    }

    if request.xhr?
      render :json => result 
    else
      render "layouts/dash", :layout => false 
    end

  end

  def create_claim
    authorize! :index, Assessable::Assessment

    assessment = Assessable::Assessment.find(params[:assessment_id])

    if params[:claim].has_key?(:copy) && params[:claim][:copy]
      copyable_attributes = Assessable::Claim.find(params[:claim][:copy_id]).attributes
      copyable_attributes[:assessment_id] = assessment.id
      attrs = copyable_attributes
    else
      params[:claim][:account_id] = current_tenant.id
      params[:claim][:assessment_id] = params[:assessment_id]
      attrs = params[:claim]
    end

    attrs[:creator] = current_user.id
    claim = Assessable::Claim.create! ActionController::Parameters.new(attrs).permit!

    render :json => claim

  end

  def update_claim
    authorize! :index, Assessable::Assessment

    claim = Assessable::Claim.find(params[:id])

    params[:claim].delete :account_id
    params[:claim].delete :id
    params[:claim].delete :key
    params[:claim].delete :verdict_id if params[:claim].has_key?(:verdict_id) && params[:claim][:verdict_id].nil?
    params[:claim].delete :point

    # TODO: explicitly grab params  
    claim.update_attributes params[:claim].permit!

    if claim.assessment.complete
      claim.assessment.update_verdict
      claim.assessment.save
    end

    render :json => claim

  end

  def destroy_claim
    authorize! :index, Assessable::Assessment

    claim = Assessable::Claim.find(params[:id])

    claim.destroy

    render :json => {:id => params[:id]}
  end

  def update
    authorize! :index, Assessable::Assessment
    
    # TODO: explicitly grab params    
    assessment = Assessable::Assessment.find(params[:assessment][:id])
    complete = assessment.complete

    params[:assessment].delete :id
    params[:assessment].delete :account_id
    params[:assessment].delete :point
    params[:assessment].delete :key

    if assessment.complete
      assessment.update_verdict()
    end
    assessment.update_attributes params[:assessment].permit!
    assessment.save

    if !complete && assessment.complete
      assessment.update_verdict()
      assessment.published_at = Time.now.utc      
      assessment.save

      ActiveSupport::Notifications.instrument("assessment_completed", 
        :assessment => assessment,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    render :json => assessment
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
