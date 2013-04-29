class ProposalsController < ApplicationController

  protect_from_forgery

  respond_to :json, :html
  
  def index

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
    return if !proposal || cannot?(:read, proposal)

    @can_update = can? :update, proposal
    @can_destroy = can? :destroy, proposal

    ApplicationController.reset_user_activities(session, proposal) if !session.has_key?(proposal.id)

    position = current_user ? current_user.positions.published.where(:proposal_id => proposal.id).last : !session["position-#{proposal.id}"].nil? ? Position.find(session["position-#{proposal.id}"]) : nil
    position ||= Position.create!( 
      :stance => 0.0, 
      :proposal_id => proposal.id, 
      :user_id => current_user ? current_user.id : nil,
      :account_id => current_tenant.id
    )

    #TODO: return just "points" and "included points" and let client sort through them?
    response = {
      :points => {
        :pros => Point.mask_anonymous_users(proposal.points.viewable.pros.public_fields, current_user),
        :cons => Point.mask_anonymous_users(proposal.points.viewable.cons.public_fields, current_user),
        :included_pros => Point.included_by_stored(current_user, proposal, session[proposal.id][:deleted_points].keys).where(:is_pro => true).select('points.id') + Point.included_by_unstored(session[proposal.id][:included_points].keys, proposal).where(:is_pro => true).select('points.id'),
        :included_cons => Point.included_by_stored(current_user, proposal, session[proposal.id][:deleted_points].keys).where(:is_pro => false).select('points.id') + Point.included_by_unstored(session[proposal.id][:included_points].keys, proposal).where(:is_pro => false).select('points.id')
        },
      #TODO: the last where prevents db caching; can be avoided
      :positions => proposal.positions.published.where("id != #{position.id}").public_fields,
      :position => position
    }
    
    #@proposal = {:data => response, :long_id => @proposal.long_id}.to_json

    respond_to do |format|
      format.json {render :json => response}
      format.html
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

    render :json => proposal
    
  end

  def update
    # TODO: this edit will fail for those who do not have an account & whose session timed out, but try to edit following admin_id link
    @proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :update, @proposal
    publicity_changed = params[:proposal].has_key?(:publicity) && params[:proposal][:publicity] == '0'

    if publicity_changed
      before_attributes = @proposal.attributes
    end

    # TODO: explicitly grab params
    @proposal.update_attributes!(params[:proposal])

    if publicity_changed
      users = []
      inviter = nil

      if before_attributes['access_list'].nil? || before_attributes['access_list'] == '' 
        if !current_user.nil?
          inviter = current_user
        end
        users = @proposal.access_list.gsub(' ', '').split(',')
      else
        before = before_attributes['access_list'].gsub(' ', '').split(',').to_set
        after = @proposal.access_list.gsub(' ', '').split(',').to_set
        users = after - before
      end

      ActiveSupport::Notifications.instrument("alert_proposal_publicity_changed", 
        :proposal => @proposal,
        :users => users,
        :inviter => inviter,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )
    end

    response = {
      :success => true,
      :access_list => @proposal.access_list,
      :publicity => @proposal.publicity,
      :active => @proposal.active
    }
    render :json => response.to_json
  end

  def destroy
    @proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :destroy, @proposal
    @proposal.destroy
    render :json => {:success => true}
  end

end
