module Invitations #defined in subdomain_controller
end

class ProposalController < ApplicationController
  include Invitations

  respond_to :json

  def index
    dirty_key "/proposals"
    render :json => []
  end

  def show
    proposal = Proposal.find_by_id(params[:id]) || Proposal.find_by_slug(params[:id])
    if !proposal
      render :json => { errors: ["not found"] }, :status => :not_found
      return 
    end
    authorize! "read proposal", proposal

    dirty_key "/proposal/#{proposal.slug}"
    render :json => []
  end

  def create
    # TODO: slug should be validated as a legit url

    authorize! 'create proposal'

    fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage', 'description_fields']
    proposal = params.select{|k,v| fields.include? k}

    if params.has_key?('roles') && params.has_key?(:invitations) && params[:invitations]
      params['roles'] = process_invitations(params['roles'], params[:invitations], proposal)
    end 

    serialized_fields = ['roles']
    for field in serialized_fields
      if params.has_key? field
        proposal[field] = JSON.dump params[field]
      end
    end

    proposal.update({
          :published => true,
          :user_id => current_user.id,
          :subdomain_id => current_subdomain.id, 
          :active => true
        })

    proposal = Proposal.new proposal

    proposal.save

    original_id = key_id(params[:key])
    result = proposal.as_json
    result['key'] = "/proposal/#{proposal.id}?original_id=#{original_id}"

    ActiveSupport::Notifications.instrument("proposal:published", 
      :proposal => proposal,
      :current_subdomain => current_subdomain
    )

    write_to_log({
      :what => 'created new proposal',
      :where => request.fullpath,
      :details => {:proposal => "/#{proposal.slug}"}
    })

    render :json => [result]

  end

  def update

    proposal = Proposal.find params[:id]

    if params.has_key?(:is_following) 
      follows = proposal.get_explicit_follow(current_user) 
      if params[:is_following] != (follows ? follows.follow : true)
        # if is following has changed, that means the user has explicitly expressed 
        # whether they want to be subscribed or not
        proposal.follow! current_user, {:follow => params[:is_following], :explicit => true}
      end
    end

    if permit('update proposal', proposal) > 0
      fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage', 'description_fields']
      updated_fields = params.select{|k,v| fields.include?(k) && v != proposal[k]}

      if params.has_key?('roles') && params.has_key?(:invitations) && params[:invitations]
        params['roles'] = process_invitations(params['roles'], params[:invitations], proposal)
      end 

      serialized_fields = ['roles']
      for field in serialized_fields
        if params.has_key? field
          updated_fields[field] = JSON.dump params[field]
        end
      end


      proposal.update_attributes! updated_fields
      dirty_key('/proposals')

      if updated_fields.include?('name') || updated_fields.include?('description')
        ActiveSupport::Notifications.instrument("proposal:updated", 
          :model => proposal,
          :current_subdomain => current_subdomain
        )
      end
    end

    dirty_key "/proposal/#{proposal.id}"
    render :json => []
  end

  def destroy
    proposal = Proposal.find(params[:id])
    authorize! 'delete proposal', proposal
    proposal.destroy
    render :json => {:success => true}
  end

end


