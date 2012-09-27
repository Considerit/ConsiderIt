class Moderatable::ModeratableController < ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :notice => 'Please login first to access the moderation panel'
    return
  end

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    
    authorize! :index, Moderatable::Moderation

    @classes_to_moderate = Moderatable::Moderation.classes_to_moderate

    @existing_moderations = {}
    @objs_to_moderate = {}
    @classes_to_moderate.each do |mc|
      
      @existing_moderations[mc.name] = {}
      if mc == Commentable::Comment
        comments = []
        mc.moderatable_objects.call.each do |comment|
          if comment.commentable_type != 'Point' || comment.root_object.proposal.active 
            comments.push(comment)
          end
        end
        @objs_to_moderate[mc.name] = comments
        objs = @objs_to_moderate[mc.name].map{|x| x.id}.compact
        records = Moderatable::Moderation.where(:moderatable_type => mc.name)
        if objs.length > 0
          records = records.where("moderatable_id in (#{objs.join(',')})")
        end
        records = records.includes(:user)
      else
        @objs_to_moderate[mc.name] = mc.moderatable_objects.call
        records = Moderatable::Moderation.where(:moderatable_type => mc.name).includes(:user)
      end
      records.each do |mod|
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