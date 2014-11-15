class ProposalController < ApplicationController

  respond_to :json

  def index
    dirty_key "/proposals"
    render :json => []
  end

  def show
    proposal = Proposal.find_by_id(params[:id]) || Proposal.find_by_long_id(params[:id])
    if !proposal || cannot?(:read, proposal)
      render :json => { errors: ["not found"] }, :status => :not_found
      return 
    end

    dirty_key "/proposal/#{proposal.long_id}"
    render :json => []
  end

  def create
    # TODO: long_id should be validated as a legit url
    
    fields = ['long_id', 'name', 'cluster', 'description', 'active', 'hide_on_homepage']
    proposal = params.select{|k,v| fields.include? k}

    proposal.update({
          :published => true,
          :user_id => current_user.id,
          :account_id => current_tenant.id, 
          :active => true
        })

    proposal = Proposal.new proposal
    authorize! :create, proposal

    proposal.save

    original_id = key_id(params[:key])
    result = proposal.as_json
    result['key'] = "/proposal/#{proposal.id}?original_id=#{original_id}"
    remap_key(params[:key], "/proposal/#{proposal.id}")

    # dirty_key "/proposal/#{proposal.id}"

    write_to_log({
      :what => 'created new proposal',
      :where => request.fullpath,
      :details => {:proposal => "/#{proposal.long_id}"}
    })

    render :json => [result]

  end


  # def old_create
  #   description = params[:proposal][:description] || ''

  #   # NOTE: default hashtags haven't been used since Occupy deployment. Purge from system.
  #   if current_tenant.default_hashtags && description.index('#').nil?
  #     description += " #{current_tenant.default_hashtags}"
  #   end

  #   # TODO: handle remote possibility of name collisions?
  #   # TODO: explicitly grab parameters
  #   params[:proposal].update({
  #     :long_id => SecureRandom.hex(5),
  #     :account_id => current_tenant.id, 
  #     :admin_id => SecureRandom.hex(6),  #NOTE: admin_id never used, should be purged from system
  #     :user_id => current_user ? current_user.id : nil,
  #     :description => description,
  #   })

  #   proposal = Proposal.create params[:proposal].permit!

  #   authorize! :create, proposal # TODO: This should happen first, I don't think cancan requires an object to authorize against

  #   proposal.save

  #   # why do we subscribe the creator to email notifications for new proposals by other people?
  #   current_tenant.follow!(current_user, :follow => true, :explicit => false)

  #   proposal.follow!(current_user, :follow => true, :explicit => false)

  #   data = proposal.full_data 

  #   render :json => data
    
  # end



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

    if can?(:update, proposal)
      fields = ['long_id', 'name', 'cluster', 'description', 'active', 'hide_on_homepage']
      updated_fields = params.select{|k,v| fields.include? k}
      proposal.update_attributes! updated_fields
      dirty_key('/proposals')
    end

    dirty_key "/proposal/#{proposal.id}"
    render :json => []
  end


  def old_update
    # ASSUMPTION: a proposal cannot become unpublished after it has been published
    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :update, proposal

    private_discussion = (params.has_key?(:publicity) && params[:publicity] == '0') || proposal.publicity == 0

    published_now = params.has_key?(:published) && params[:published] == 'true' && !proposal.published

    notify_private_accessors = private_discussion && (published_now || proposal.published)

    # we don't want to send emails to people who have already been
    # invited via email. This only applies to proposals that have
    # already been published, because email invitations aren't sent
    # out until publishing. We can avoid double sending invitations by
    # grabbing the access list of the proposal as set *before* this
    # current update.
    existing_access_list = notify_private_accessors && !published_now ? proposal.attributes['access_list'] : nil

    # TODO: explicitly grab params
    proposal.update_attributes! params.permit!

    if notify_private_accessors
      users = []
      inviter = nil

      if existing_access_list.nil? || existing_access_list == '' 
        if !current_user.nil? && current_user.registration_complete
          inviter = current_user
        end
        users = proposal.access_list.gsub(' ', '').split(',')
      else
        before = existing_access_list.gsub(' ', '').split(',').to_set
        after = proposal.access_list.gsub(' ', '').split(',').to_set
        users = after - before
      end

      ActiveSupport::Notifications.instrument("alert_proposal_publicity_changed", 
        :proposal => proposal,
        :users => users,
        :inviter => inviter,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    if published_now
      ActiveSupport::Notifications.instrument("proposal:published", 
        :proposal => proposal,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    elsif !published_now && proposal.published
      ActiveSupport::Notifications.instrument("proposal:updated", 
        :model => proposal,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )      
    end

    response = {
      :success => true,
      :access_list => proposal.access_list,
      :publicity => proposal.publicity,
      :published => proposal.published,
      :active => proposal.active,
      :proposal => proposal
    }
    render :json => response.to_json
  end

  def destroy
    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :destroy, proposal
    proposal.destroy
    render :json => {:success => true}
  end

end


