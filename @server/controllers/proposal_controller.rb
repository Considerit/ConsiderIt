class ProposalController < ApplicationController

  respond_to :json

  def index
    dirty_key "/proposals"
    render :json => []
  end

  def show
    proposal = Proposal.find_by_id(params[:id]) || Proposal.find_by_slug(params[:id])
    if !proposal || !proposal.can?(:read)
      render :json => { errors: ["not found"] }, :status => :not_found
      return 
    end

    dirty_key "/proposal/#{proposal.slug}"
    render :json => []
  end

  def create
    # TODO: slug should be validated as a legit url
    
    fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage']
    proposal = params.select{|k,v| fields.include? k}

    proposal.update({
          :published => true,
          :user_id => current_user.id,
          :subdomain_id => current_subdomain.id, 
          :active => true
        })

    proposal = Proposal.new proposal
    authorize! :create, proposal

    proposal.save

    original_id = key_id(params[:key])
    result = proposal.as_json
    result['key'] = "/proposal/#{proposal.id}?original_id=#{original_id}"

    # dirty_key "/proposal/#{proposal.id}"

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

    if proposal.can?(:update)
      fields = ['slug', 'name', 'cluster', 'description', 'active', 'hide_on_homepage']
      updated_fields = params.select{|k,v| fields.include? k}
      proposal.update_attributes! updated_fields
      dirty_key('/proposals')
    end

    dirty_key "/proposal/#{proposal.id}"
    render :json => []
  end


  # def old_update
  #   # ASSUMPTION: a proposal cannot become unpublished after it has been published
  #   proposal = Proposal.find_by_slug(params[:slug])
  #   authorize! :update, proposal

  #   private_discussion = (params.has_key?(:publicity) && params[:publicity] == '0') || proposal.publicity == 0

  #   published_now = params.has_key?(:published) && params[:published] == 'true' && !proposal.published

  #   notify_private_accessors = private_discussion && (published_now || proposal.published)

  #   # we don't want to send emails to people who have already been
  #   # invited via email. This only applies to proposals that have
  #   # already been published, because email invitations aren't sent
  #   # out until publishing. We can avoid double sending invitations by
  #   # grabbing the access list of the proposal as set *before* this
  #   # current update.
  #   existing_access_list = notify_private_accessors && !published_now ? proposal.attributes['access_list'] : nil

  #   # TODO: explicitly grab params
  #   proposal.update_attributes! params.permit!

  #   if notify_private_accessors
  #     users = []
  #     inviter = nil

  #     if existing_access_list.nil? || existing_access_list == '' 
  #       if !current_user.nil? && current_user.registered
  #         inviter = current_user
  #       end
  #       users = proposal.access_list.gsub(' ', '').split(',')
  #     else
  #       before = existing_access_list.gsub(' ', '').split(',').to_set
  #       after = proposal.access_list.gsub(' ', '').split(',').to_set
  #       users = after - before
  #     end

  #     ActiveSupport::Notifications.instrument("alert_proposal_publicity_changed", 
  #       :proposal => proposal,
  #       :users => users,
  #       :inviter => inviter,
  #       :current_subdomain => current_subdomain
  #     )
  #   end

  #   if published_now
  #     ActiveSupport::Notifications.instrument("proposal:published", 
  #       :proposal => proposal,
  #       :current_subdomain => current_subdomain
  #     )
  #   elsif !published_now && proposal.published
  #     ActiveSupport::Notifications.instrument("proposal:updated", 
  #       :model => proposal,
  #       :current_subdomain => current_subdomain
  #     )      
  #   end

  #   response = {
  #     :success => true,
  #     :access_list => proposal.access_list,
  #     :publicity => proposal.publicity,
  #     :published => proposal.published,
  #     :active => proposal.active,
  #     :proposal => proposal
  #   }
  #   render :json => response.to_json
  # end

  def destroy
    proposal = Proposal.find(params[:id])
    authorize! :destroy, proposal
    proposal.destroy
    render :json => {:success => true}
  end

end


