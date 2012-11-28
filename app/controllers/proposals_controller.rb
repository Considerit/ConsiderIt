#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class ProposalsController < ApplicationController
  #include ActsAsFollowable::ControllerMethods

  protect_from_forgery

  POINTS_PER_PAGE = 4

  respond_to :json, :html
  
  def index

    if request.xhr?
      filter_by_metric = params.has_key? :metric
      filter_by_tag = params.has_key? :tag

      session[:filters] ||= {:tag => nil, :metric => 'activity'}

      if filter_by_tag
        # if the user has clicked on the selected tag, then unselect
        session[:filters][:tag] = session[:filters][:tag] == params[:tag] ? nil : params[:tag]
      elsif filter_by_metric
        session[:filters][:metric] = params[:metric]
      end

      proposal_list = session[:filters][:tag] ? Proposal.tagged_with(session[:filters][:tag]) : Proposal
      proposal_list = proposal_list.public.active.order("#{session[:filters][:metric]} DESC").limit(100)

      proposals = render_to_string :partial => "proposals/list_output/list", :locals => { 
        :proposals => proposal_list, :style => 'blocks', :hide_initially => false }
      render :json => {:proposals => proposals, :current_tag => session[:filters][:tag], :current_metric => session[:filters][:metric]}.to_json
    else
      render
    end

  end


  # Shows the proposal. If it is a json request, it will just return the voter segments
  def show
    @user = current_user
 
    if params.has_key?(:id)
      @proposal = Proposal.find(params[:id])
    elsif params.has_key?(:long_id)
      @proposal = Proposal.find_by_long_id(params[:long_id])
    elsif params.has_key?(:admin_id)
      @proposal = Proposal.find_by_admin_id(params[:admin_id])
    else
      redirect_to root_path, :notice => 'Invalid request.'
      return
    end

    if !@proposal
      redirect_to root_path, :notice => 'That proposal does not exist.'
      return
    end

    if cannot?(:read, @proposal)
      store_location request.path
      redirect_to new_user_registration_path(:redirect_already_set => true, :user => params.fetch(:u, nil), :token => params.fetch(:t,nil)), :notice => 'That proposal can only be viewed by authorized users.'
      return  
    end

    @can_update = can? :update, @proposal
    @can_destroy = can? :destroy, @proposal

    @position = current_user ? current_user.positions.published.where(:proposal_id => @proposal.id).first : nil

    @results_page = true
    @page = 1

    if !!request.xhr?
      @segments = Array.new(7)
      (0..6).each do |bucket|
        qry = @proposal.points.viewable.includes(:user).ranked_for_stance_segment(bucket)
        @segments[bucket] = [qry.pros.page( 1 ).per( POINTS_PER_PAGE ),
          qry.cons.page( 1 ).per( POINTS_PER_PAGE )]
      end

      segments = render_to_string :partial => 'proposals/segment_positions'
    
      response = {
        :segments => segments,
        :success => true
      }
      render :json => response.to_json

    else
      #@title = "#{@proposal.category} #{@proposal.designator} #{@proposal.short_name}"
      @title = "#{@proposal.short_name}"
      @keywords = "#{current_tenant.identifier} #{@proposal.category} #{@proposal.designator} #{@proposal.name}"
      @description = "Explore the opinions of citizen participants for #{current_tenant.identifier} #{@proposal.category} #{@proposal.designator} #{@proposal.short_name}. You'll be voting on it in the November 2012 election!"
      
      @positions = @proposal.positions.published.includes(:user)
      @pro_points = @proposal.points.viewable.includes(:user).pros.ranked_overall.page( 1 ).per( POINTS_PER_PAGE )
      @con_points = @proposal.points.viewable.includes(:user).cons.ranked_overall.page( 1 ).per( POINTS_PER_PAGE )

    end
 
    #Point.update_relative_scores

    #@comments = @proposal.root_comments
    #@comment = Comment.new      
    #@reflectable = true    
    
  end

  # def index
  #   headers['Content-Type'] = 'application/xml'

  #   @proposals = Proposal.all
  #   respond_to do |format|
  #     format.xml {  } # sitemap is a named scope
  #     format.html {  }
  #   end

  # end

  def create

    # TODO: handle remote possibility of name collisions?
    params[:proposal][:long_id] = SecureRandom.hex(5)
    params[:proposal][:admin_id] = SecureRandom.hex(6)
    params[:proposal][:description] ||= ''

    if current_user
      params[:proposal][:user_id] = current_user.id
    end

    if current_tenant.default_hashtags && params[:proposal][:description].index('#').nil?
      params[:proposal][:description] += " #{current_tenant.default_hashtags}"
    end
    @proposal = Proposal.create(params[:proposal])
    authorize! :create, @proposal
    @proposal.save
    @proposal.track!

    current_tenant.follow!(current_user, :follow => true, :explicit => false)
    @proposal.follow!(current_user, :follow => true, :explicit => false)

    redirect_to new_proposal_position_path(@proposal.long_id)
    
  end

  def update
    # TODO: this edit will fail for those who do not have an account & whose session timed out, but try to edit following admin_id link
    @proposal = Proposal.find_by_long_id(params[:long_id])
    authorize! :update, @proposal
    publicity_changed = params[:proposal].has_key?(:publicity) && params[:proposal][:publicity] == '0'

    if publicity_changed
      before_attributes = @proposal.attributes
    end

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
    redirect_to root_path
  end

end
