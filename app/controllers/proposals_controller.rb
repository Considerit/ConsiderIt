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


    data = proposal.full_data current_tenant, current_user, session[proposal.id]

    # position = ProposalsController.get_position_for_user(proposal, current_user, session)
    # data[:position] = position

    respond_to do |format|
      format.json {render :json => data}
      format.html {
        @current_proposal = data.to_json
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

    proposal = Proposal.create(params[:proposal])
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
    # TODO: this edit will fail for those who do not have an account & whose session timed out, but try to edit following admin_id link
    proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :update, proposal
    publicity_changed = params[:proposal].has_key?(:publicity) && params[:proposal][:publicity] == '0'

    if publicity_changed
      before_attributes = proposal.attributes
    end

    # TODO: explicitly grab params
    proposal.update_attributes!(params[:proposal])

    if publicity_changed
      users = []
      inviter = nil

      if before_attributes['access_list'].nil? || before_attributes['access_list'] == '' 
        if !current_user.nil?
          inviter = current_user
        end
        users = proposal.access_list.gsub(' ', '').split(',')
      else
        before = before_attributes['access_list'].gsub(' ', '').split(',').to_set
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
    elsif proposal.published
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
    position ||= Position.create!( 
      :stance => 0.0, 
      :proposal_id => proposal.id, 
      :long_id => proposal.long_id,
      :user_id => current_user ? current_user.id : nil,
      :account_id => proposal.account_id
    )

    position


  end
end


