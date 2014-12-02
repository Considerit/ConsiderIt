class AssessmentController < ApplicationController  
  respond_to :json

  def show
    authorize! :index, Assessment

    assessment = Assessment.find(params[:id])
    #TODO: authorize against this specific assessment?

    dirty_key "/assessment/#{params[:id]}"
    render :json => []
  end

  def update
    authorize! :index, Assessment
    
    fields = ["complete", "reviewable", "notes"]
    updates = params.select{|k,v| fields.include? k}

    assessment = Assessment.find(params[:id])
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
        :current_subdomain => current_subdomain,
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
      'subdomain_id' => current_subdomain.id,
      'assessable_type' => 'Point',
      'assessable_id' => point.id
    }

    request = Assessable::Request.new request

    assessment = Assessment.where(:assessable_type => request['assessable_type'], :assessable_id => request['assessable_id']).first
    if !assessment
      create_attrs = {
        :subdomain_id => current_subdomain.id, 
        :assessable_type => request['assessable_type'],
        :assessable_id => request['assessable_id'] }
        
      assessment = Assessment.create! create_attrs

      ActiveSupport::Notifications.instrument("new_assessment_request", 
        :assessment => assessment,
        :current_subdomain => current_subdomain
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

    dirty_key "/comments/#{point.id}"

    render :json => [result, assessment] 
  end


end



