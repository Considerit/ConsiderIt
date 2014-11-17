class ClaimController < ApplicationController  
  respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :errors => [current_user.nil? ? 'not logged in' : 'not authorized']
    }
    render :json => result 
    return
  end

  def show 
    dirty_key "/claim/#{params[:id]}"
    render :json => []
  end

  def create
    authorize! :index, Assessable::Assessment

    assessment = Assessable::Assessment.find key_id(params['assessment'])

    fields = ["claim_restatement", "result"]

    attrs = params.select{|k,v| fields.include? k}
    attrs.update({
          :assessment_id => key_id(params['assessment']),
          :subdomain_id => current_subdomain.id,
          :creator => current_user.id
        })

    if params['verdict']
      attrs['verdict_id'] = key_id(params['verdict'])
    end
    
    claim = Assessable::Claim.create! attrs

    original_id = key_id(params[:key])
    result = claim.as_json
    result['key'] = "/claim/#{claim.id}?original_id=#{original_id}"

    dirty_key("/assessment/#{assessment.id}")
    render :json => [result]
  end

  def update
    authorize! :index, Assessable::Assessment

    claim = Assessable::Claim.find(params[:id])

    fields = ["claim_restatement", "result"]
    attrs = params.select{|k,v| fields.include? k}
    attrs['assessment_id'] = key_id(params['assessment'])

    if params['verdict']
      attrs['verdict_id'] = key_id(params['verdict'])
    end

    if params.has_key?('approver')
      if params['approver']
        attrs['approver'] = key_id params['approver']
      else
        attrs['approver'] = nil
      end
    end

    claim.update_attributes attrs

    if claim.assessment.complete
      claim.assessment.update_verdict
      claim.assessment.save
      dirty_key "/assessment/#{claim.assessment_id}"
    end

    dirty_key "/claim/#{claim.id}"

    render :json => []
  end


  def destroy
    authorize! :index, Assessable::Assessment

    claim = Assessable::Claim.find(params[:id])

    assessment = claim.assessment

    claim.destroy

    if assessment.complete
      assessment.update_verdict
      assessment.save
    end

    dirty_key "/assessment/#{claim.assessment_id}"

    render :json => []
  end

end