class ProposalController < ApplicationController

  protect_from_forgery

  respond_to :json, :html

  def index
    proposals = []

    #active = params.has_key?(:active) && params[:active] == 'true'

    # top = Proposal.where("top_con IS NOT NULL AND active=#{active}").select(:top_con).map {|x| x.top_con}.compact +
    #       Proposal.where("top_pro IS NOT NULL AND active=#{active}").select(:top_pro).map {|x| x.top_pro}.compact 
    if params.has_key?(:target)
      target = params[:target]
      proposals = Proposal.open_to_public.where(:targettable => true).where("tags LIKE '%#{target}%'")
    else
      proposals = Proposal.open_to_public.browsable
    end

    top = proposals.where("top_con IS NOT NULL").select(:top_con).map {|x| x.top_con}.compact +
          proposals.where("top_pro IS NOT NULL").select(:top_pro).map {|x| x.top_pro}.compact 
    
    top_points = {}
    Point.where('id in (?)', top).public_fields.each do |pnt|
      top_points[pnt.id] = pnt
    end

    render :json => {
      :proposals => proposals.public_fields,
      :points => top_points.values
    }
  end

  def show
    proposal = Proposal.find_by_id(params[:id]) || Proposal.find_by_long_id(params[:id])
    return if !proposal 

    if cannot?(:read, proposal)
      render :json => {:result => 'failure', :reason => 'Access denied'}
    else
      pp 'reseting user activities'
      ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)
      data = proposal.full_data current_tenant, current_user, session[proposal.id], can?(:manage, proposal)
      render :json => data
    end


  end

  def create
    description = params[:proposal][:description] || ''

    # NOTE: default hashtags haven't been used since Occupy deployment. Purge from system.
    if current_tenant.default_hashtags && description.index('#').nil?
      description += " #{current_tenant.default_hashtags}"
    end

    # TODO: handle remote possibility of name collisions?
    # TODO: explicitly grab parameters
    params[:proposal].update({
      :long_id => SecureRandom.hex(5),
      :account_id => current_tenant.id, 
      :admin_id => SecureRandom.hex(6),  #NOTE: admin_id never used, should be purged from system
      :user_id => current_user ? current_user.id : nil,
      :description => description,
    })

    proposal = Proposal.create params[:proposal].permit!

    authorize! :create, proposal # TODO: This should happen first, I don't think cancan requires an object to authorize against

    proposal.save

    #########
    # Wrong! This should only happen when a proposal is published! And care needs to be taken to filter this according to its publicity!
    proposal.track! 
    #########

    # why do we subscribe the creator to email notifications for new proposals by other people?
    current_tenant.follow!(current_user, :follow => true, :explicit => false)


    proposal.follow!(current_user, :follow => true, :explicit => false)

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    data = proposal.full_data current_tenant, current_user, session[proposal.id]

    # opinion = ProposalsController.get_opinion_for_user(proposal, current_user, session)
    # data[:opinion] = opinion
    render :json => data
    
  end

  def update
    # ASSUMPTION: a proposal cannot become unpublished after it has been published

    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :update, proposal

    private_discussion = (params[:proposal].has_key?(:publicity) && params[:proposal][:publicity] == '0') || proposal.publicity == 0

    published_now = params[:proposal].has_key?(:published) && params[:proposal][:published] == 'true' && !proposal.published

    notify_private_accessors = private_discussion && (published_now || proposal.published)

    # we don't want to send emails to people who have already been invited via email. This only applies to proposals that
    # have already been published, because email invitations aren't sent out until publishing. We can avoid double sending
    # invitations by grabbing the access list of the proposal as set *before* this current update. 
    existing_access_list = notify_private_accessors && !published_now ? proposal.attributes['access_list'] : nil

    # TODO: explicitly grab params
    proposal.update_attributes! params[:proposal].permit!

    if notify_private_accessors
      users = []
      inviter = nil

      if existing_access_list.nil? || existing_access_list == '' 
        if !current_user.nil?
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
      # :opinion => ProposalsController.get_opinion_for_user(proposal, current_user, session)
    }
    render :json => response.to_json
  end

  def destroy
    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :destroy, proposal
    proposal.destroy
    render :json => {:success => true}
  end

  def self.get_opinion_for_user(proposal, current_user, session)
    opinion = current_user ? current_user.opinions.published.where(:proposal_id => proposal.id).last : !session["opinion-#{proposal.id}"].nil? ? Opinion.find(session["opinion-#{proposal.id}"]) : nil
    opinion ||= Opinion.create!(ActionController::Parameters.new({ 
      :stance => 0.0, 
      :proposal_id => proposal.id, 
      :long_id => proposal.long_id,
      :user_id => current_user ? current_user.id : nil,
      :account_id => proposal.account_id
    }).permit!)

    opinion


  end
end


