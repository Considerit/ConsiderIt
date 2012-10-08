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
    @assessment = Assessable::Assessment.find(params[:id])

    render 'assessable/edit'
  end

  def create_claim
    params[:claim][:account_id] = current_tenant.id
    params[:claim][:assessment_id] = params[:assessment_id]
    @assessment = Assessable::Assessment.find(params[:assessment_id])
    claim = Assessable::Claim.create!(params[:claim])
    redirect_to edit_assessment_path(@assessment)

  end

  def update_claim
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

  def update
    redirect_to assessment_index_path
    assessment = Assessable::Assessment.find(params[:assessment][:id])
    complete = assessment.complete
    assessment.update_attributes(params[:assessment])
    if assessment.complete
      assessment.update_overall_verdict
    end

    assessment.save

    if !complete && assessment.complete
      #TODO: if fact-check is being completed, instrument notification to appropriate parties
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

    request = Assessable::Request.new(params[:request])
    assessment = Assessable::Assessment.where(:assessable_type => assessable_type, :assessable_id => assessable_id).first
    if !assessment
      #TODO: instrument event so notification can be sent out
      assessment = Assessable::Assessment.create!({:account_id => current_tenant.id, :assessable_type => assessable_type, :assessable_id => assessable_id})
    end
    request.assessment = assessment
    request.save

    render :json => {:success => true}.to_json
  end


end