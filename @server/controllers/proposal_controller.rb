class ProposalController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :update_images_hack

  include SubdomainController::Invitations

  respond_to :json

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

    fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage', 'description_fields']
    attrs = params.select{|k,v| fields.include? k}

    errors = validate_input attrs, nil


    if attrs.include?('cluster') && !!attrs['cluster'] && attrs['cluster'].length > 0 
      attrs['cluster'] = attrs['cluster'].strip
    end

    if errors.length == 0

      attrs.update({
            :published => true,
            :user_id => current_user.id,
            :subdomain_id => current_subdomain.id, 
            :active => true
          })

      proposal = Proposal.new attrs

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

      Notifier.create_notification 'new', proposal
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
      fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage', 'description_fields']

      if params.has_key?('cluster') && params['cluster'] != proposal.cluster 
        if permit('set category', params['cluster']) <= 0 
          params.delete('cluster')
        end 
      end

      updated_fields = params.select{|k,v| fields.include?(k) && v != proposal[k]}

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
        if updated_fields.has_key?('description_fields') && !current_user.is_admin?
          # Sanitize description_fields[i].html
          updated_fields['description_fields'] =
            JSON.dump(JSON.parse(updated_fields['description_fields']).map { |field|
                        field['html'] = sanitize_helper(field['html'])
                        field
                      })
        end 

        update_roles(proposal)

        proposal.update_attributes! updated_fields

        if text_updated
          # Perhaps we shouldn't enable this until we have an edit history
          # Notifier.create_notification 'edited', proposal, protagonist: current_user
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
      # need to update these attributes later on after proposal is created
      if params.has_key?('invitations') && params['invitations']
        params['roles'] = process_and_send_invitations(params['roles'], params['invitations'], proposal)
      end

      # rails replaces [] with nil in params for some reason...
      params['roles'].each do |k,v|
        params['roles'][k] = [] if !v
      end
      proposal.roles = JSON.dump params['roles']
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

  def copy_to_subdomain

    proposal = Proposal.find(params[:id])
    dest = Subdomain.find(params[:subdomain_id])

    deep_clone = proposal.deep_clone :include => [:opinions, {:points => [:comments, :inclusions]}], :validate => false
    deep_clone.save

    # copy to different subdomain
    
    qry = "UPDATE {TABLE} SET subdomain_id=#{dest.id} WHERE {SELECT_ID}={ID}"
    def copy_to(table, select_id, id, qry)
      if id
        my_query = qry.gsub('{TABLE}', table)
                      .gsub('{SELECT_ID}', select_id)
                      .gsub('{ID}', "#{id}")
        ActiveRecord::Base.connection.execute(my_query)
      else
        pp "OOPS, couldn't update something in #{table}"
      end
    end

    for point in deep_clone.points
      for comment in point.comments
        copy_to 'comments', 'point_id', point.id, qry
        comment.user.add_to_active_in(dest)
      end

      for inclusion in point.inclusions
        copy_to 'inclusions', 'point_id', point.id, qry
      end

      copy_to 'points', 'proposal_id', deep_clone.id, qry
      point.user.add_to_active_in(dest)
    end

    for opinion in deep_clone.opinions
      copy_to 'opinions', 'proposal_id', deep_clone.id, qry
      opinion.user.add_to_active_in(dest)
    end

    copy_to 'proposals', 'id', deep_clone.id, qry
    deep_clone.user.add_to_active_in(dest)

    redirect_to "/#{proposal.slug}"
  end

end


