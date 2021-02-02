class ProposalController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :update_images_hack

  include Invitations

  def index
    dirty_key '/proposals'
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

  def validate_input(attrs, proposal)
    errors = []

    if !attrs['name'] || attrs['name'].length == 0
      errors.append translator('errors.summary_required', 'A summary is required')
    end

    return errors
  end

  def create
    authorize! 'create proposal'

    fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage']
    attrs = params.select{|k,v| fields.include? k}.to_h

    errors = validate_input attrs, nil


    if attrs.include?('cluster') && !!attrs['cluster'] && attrs['cluster'].length > 0 
      attrs['cluster'] = attrs['cluster'].strip
    end

    if errors.length == 0
      proposal = Proposal.new attrs

      proposal.published = true
      proposal.user_id = current_user.id
      proposal.subdomain_id = current_subdomain.id 
      proposal.active = true

      proposal.save

      # need to save the proposal before potentially sending out
      # email invitations via role.
      update_roles proposal

      proposal.save

      original_id = key_id(params[:key])
      result = proposal.as_json
      result['key'] = "/proposal/#{proposal.id}?original_id=#{original_id}"

      dirty_key '/proposals'

      current_user.update_subscription_key(proposal.key, 'watched', :force => false)
      dirty_key '/current_user'

      Notifier.notify_parties 'new', proposal
      proposal.notify_moderator

      write_to_log({
        :what => 'created new proposal',
        :where => request.fullpath,
        :details => {:proposal => "/#{proposal.id}"}
      })
    else 
      result = {
        :key => params[:key],
        :errors => errors
      }
    end

    render :json => [result]

  end

  def update

    proposal = Proposal.find params[:id]
    errors = []

    if permit('update proposal', proposal) > 0
      fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage']

      if params.has_key?('cluster') && params['cluster'] != proposal.cluster 
        if permit('set category', params['cluster']) <= 0 
          params.delete('cluster')
        end 
      end

      updated_fields = params.select{|k,v| fields.include?(k) && v != proposal[k]}.to_h

      if updated_fields.include?('cluster') && updated_fields['cluster'] && updated_fields['cluster'].length > 0
        updated_fields['cluster'] = updated_fields['cluster'].strip
      end
      text_updated = updated_fields.include?('name') || updated_fields.include?('description')
      
      fields_to_validate = {}
      fields.each do |f|
        fields_to_validate[f] = updated_fields[f] || proposal[f]
      end

      errors = validate_input(fields_to_validate, proposal)
        
      if errors.length == 0

        if updated_fields.has_key?('description') && !current_user.is_admin?
          # Sanitize description
          updated_fields['description'] = sanitize_helper(updated_fields['description'])
        end 

        update_roles(proposal)

        proposal.update_attributes! updated_fields

        if text_updated
          proposal.redo_moderation
        end
      end
    end

    response = proposal.as_json
    if errors.length > 0
      response[:errors] = errors
    end

    render :json => [response]
  end

  def update_roles(proposal)
    if params.has_key?('roles')
      roles = params['roles']
      # need to update these attributes later on after proposal is created
      if params.has_key?('invitations') && params['invitations']
        roles = process_and_send_invitations(roles, params['invitations'], proposal)
      end

      # rails replaces [] with nil in params for some reason...
      roles.each do |k,v|
        roles[k] = [] if !v
      end
      proposal.roles = roles
    end
  end

  def destroy
    proposal = Proposal.find(params[:id])
    authorize! 'delete proposal', proposal
    dirty_key '/proposals'
    proposal.destroy
    render :json => {:success => true}
  end

  def update_images_hack
    proposal = Proposal.find(params[:id])
    attrs = {}
    if params['pic']
      attrs['pic'] = params['pic']
    end
    if params['banner']
      attrs['banner'] = params['banner']
    end
    proposal.update_attributes attrs
    dirty_key proposal.key
    render :json => []
  end


end


