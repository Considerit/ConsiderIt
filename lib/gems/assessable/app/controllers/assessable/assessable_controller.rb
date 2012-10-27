class Assessable::AssessableController < ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :notice => 'Please login first to access the assessment panel'
    return
  end

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    
    authorize! :index, Assessable::Assessment

    @assessments = Assessable::Assessment.order(:complete)

    render 'assessable/index'
  end

  def edit
    authorize! :index, Assessable::Assessment

    @assessment = Assessable::Assessment.find(params[:id])

    render 'assessable/edit'
  end

  def create_claim
    authorize! :index, Assessable::Assessment

    @assessment = Assessable::Assessment.find(params[:assessment_id])

    if params[:claim].has_key?(:copy) && params[:claim][:copy]
      copyable_attributes = Assessable::Claim.find(params[:claim][:copy_id]).attributes
      copyable_attributes[:assessment_id] = @assessment.id
      claim = Assessable::Claim.create!(copyable_attributes)
    else
      params[:claim][:account_id] = current_tenant.id
      params[:claim][:assessment_id] = params[:assessment_id]
      claim = Assessable::Claim.create!(params[:claim])
    end
    redirect_to edit_assessment_path(@assessment)

  end

  def update_claim
    authorize! :index, Assessable::Assessment

    claim = Assessable::Claim.find(params[:id])
    if params[:assessable_claim].has_key? :verdict
      verdict = params[:assessable_claim][:verdict]
      params[:assessable_claim][:verdict] = Assessable::Claim.translate(verdict)
    end 
    claim.update_attributes(params[:assessable_claim])
    redirect_to edit_assessment_path(claim.assessment)

    if claim.assessment.complete
      claim.assessment.update_overall_verdict
      claim.assessment.save
    end
  end

  def destroy_claim
    authorize! :index, Assessable::Assessment

    claim = Assessable::Claim.find(params[:id])
    redirect_to edit_assessment_path(claim.assessment)

    if !claim.assessment.complete
      claim.destroy
    end
  end

  def update
    authorize! :index, Assessable::Assessment
    
    redirect_to assessment_index_path
    assessment = Assessable::Assessment.find(params[:assessment][:id])
    complete = assessment.complete
    assessment.update_attributes(params[:assessment])
    if assessment.complete
      assessment.update_overall_verdict
    end

    assessment.save

    if !complete && assessment.complete
      ActiveSupport::Notifications.instrument("assessment_completed", 
        :assessment => assessment,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end


  end

  ### User facing
  # create a new assessment request
  def create
    authorize! :create, Assessable::Request

    params[:request][:user_id] = current_user.id
    params[:request][:account_id] = current_tenant.id

    assessable_type = params[:request].delete(:assessable_type)
    assessable_id = params[:request].delete(:assessable_id)

    #request = Assessable::Request.where(:user_id => current_user.id, :assessable_type => assessable_type, :assessable_id => assessable_id).first
    #if request.nil?
    request = Assessable::Request.new(params[:request])
    #end

    assessment = Assessable::Assessment.where(:assessable_type => assessable_type, :assessable_id => assessable_id).first
    if !assessment
      assessment = Assessable::Assessment.create!({:account_id => current_tenant.id, :assessable_type => assessable_type, :assessable_id => assessable_id})

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

    render :json => {:success => true}.to_json
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
    if u.has_any_role? :evaluator, :admin, :superadmin
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

    if !follow.user.email || follow.user.email.length == 0
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

    EventMailer.point_new_assessment(follow.user, assessable, assessment, mail_options, notification_type).deliver!

  end

end
