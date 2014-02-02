class ProposalsController < ApplicationController

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

    if params.has_key?(:id)
      proposal = Proposal.find(params[:id])
    elsif params.has_key?(:long_id)
      proposal = Proposal.find_by_long_id(params[:long_id])
    else
      return
    end

    #TODO: handle permissions
    return if !proposal 

    if cannot?(:read, proposal)
      respond_to do |format|
        format.json { render :json => {:result => 'failure', :reason => 'Access denied'}}
        format.html {
          @inaccessible_proposal = {:id => proposal.id, :long_id => proposal.long_id }
        }
      end
      return      
    end

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)


    data = proposal.full_data current_tenant, current_user, session[proposal.id], can?(:manage, proposal)

    # position = ProposalsController.get_position_for_user(proposal, current_user, session)
    # data[:position] = position

    respond_to do |format|
      format.html {
        @current_proposal = data.to_json
      }

      format.json {
        render :json => data
      }
    end

  end

  def create
    description = params[:proposal][:description] || ''

    if current_tenant.default_hashtags && description.index('#').nil?
      description += " #{current_tenant.default_hashtags}"
    end

    # TODO: handle remote possibility of name collisions?
    # TODO: explicitly grab parameters
    params[:proposal].update({
      :long_id => SecureRandom.hex(5),
      :account_id => current_tenant.id,
      :admin_id => SecureRandom.hex(6),
      :user_id => current_user ? current_user.id : nil,
      :description => description,
    })

    proposal = Proposal.create params[:proposal].permit!
    authorize! :create, proposal
    proposal.save
    proposal.track!

    current_tenant.follow!(current_user, :follow => true, :explicit => false)
    proposal.follow!(current_user, :follow => true, :explicit => false)

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    data = proposal.full_data current_tenant, current_user, session[proposal.id]

    # position = ProposalsController.get_position_for_user(proposal, current_user, session)
    # data[:position] = position
    render :json => data
    
  end

  def update
    # ASSUMPTION: a proposal cannot become unpublished after it has been published

    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :update, proposal


    private_discussion = (params[:proposal].has_key?(:publicity) && params[:proposal][:publicity] == '0') || proposal.publicity == 0

    published_now = params[:proposal].has_key?(:published) && params[:proposal][:published] == 'true' && !proposal.published

    notify_private_accessors = private_discussion && (published_now || proposal.published)

    if notify_private_accessors
      # if this proposal has already been published, then those users already given access have already been notified, so we
      # want to make sure not to send them another invite. If this, however, is a newly published proposal, we'll want to 
      # notify everyone in the access list, regardless of on which update they were given access to this proposal.
      existing_access_list = !published_now ? proposal.attributes['access_list'] : nil
    end

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
      # :position => ProposalsController.get_position_for_user(proposal, current_user, session)
    }
    render :json => response.to_json
  end

  def destroy
    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :destroy, proposal
    proposal.destroy
    render :json => {:success => true}
  end

  def self.get_position_for_user(proposal, current_user, session)
    position = current_user ? current_user.positions.published.where(:proposal_id => proposal.id).last : !session["position-#{proposal.id}"].nil? ? Position.find(session["position-#{proposal.id}"]) : nil
    position ||= Position.create!(ActionController::Parameters.new({ 
      :stance => 0.0, 
      :proposal_id => proposal.id, 
      :long_id => proposal.long_id,
      :user_id => current_user ? current_user.id : nil,
      :account_id => proposal.account_id
    }).permit!)

    position


  end
end


