class Moderatable::ModeratableController < ApplicationController

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    authorize! :index, Moderatable::Moderation
    @classes_to_moderate = Moderatable::Moderation.classes_to_moderate

    @existing_moderations = {}
    @objs_to_moderate = {}
    @classes_to_moderate.each do |mc|
      @objs_to_moderate[mc.name] = mc.moderatable_objects.call
      @existing_moderations[mc.name] = {}
      Moderatable::Moderation.where(:moderatable_type => mc.name).includes(:user).each do |mod|
        @existing_moderations[mc.name][mod.moderatable_id] = mod unless @existing_moderations[mc.name].has_key?(mod.moderatable_id) && @existing_moderations[mc.name][mod.moderatable_id].user_id == current_user.id
      end
    end

    render 'moderatable/index'
  end

  # create a new moderation
  def create
    authorize! :create, Moderatable::Moderation

    #params[:moderate][:status] = Moderatable::Moderation.STATUSES.index(params[:moderate].delete(:moderation_status))
    params[:moderate][:user_id] = current_user.id
    params[:moderate][:account_id] = current_tenant.id

    moderation = Moderatable::Moderation.where(:moderatable_type => params[:moderate][:moderatable_type], :moderatable_id => params[:moderate][:moderatable_id], :user_id => current_user.id).first
    
    if moderation
      moderation.status = params[:moderate][:status]
      moderation.save
    else
      moderation = Moderatable::Moderation.create!(params[:moderate])
    end

    moderatable = moderation.root_object
    moderatable.moderation_status = moderation.status
    moderatable.save

    render :json => {:success => true}.to_json
  end

end