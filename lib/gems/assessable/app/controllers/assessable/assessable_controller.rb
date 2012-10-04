class Assessable::AssessableController < ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :notice => 'Please login first to access the assessment panel'
    return
  end

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    
    authorize! :index, Assessable::Assessment

    @classes_to_moderate = Assessable::Assessment.classes_to_moderate

    @existing_moderations = {}
    @objs_to_moderate = {}
    @classes_to_moderate.each do |mc|
      
      @existing_moderations[mc.name] = {}
      if mc == Commentable::Comment
        comments = []
        mc.assessable_objects.call.each do |comment|
          if comment.commentable_type != 'Point' || comment.root_object.proposal.active 
            comments.push(comment)
          end
        end
        @objs_to_moderate[mc.name] = comments
        objs = @objs_to_moderate[mc.name].map{|x| x.id}.compact
        records = Assessable::Assessment.where(:assessable_type => mc.name)
        if objs.length > 0
          records = records.where("assessable_id in (#{objs.join(',')})")
        end
        records = records.includes(:user)
      else
        @objs_to_moderate[mc.name] = mc.assessable_objects.call
        records = Assessable::Assessment.where(:assessable_type => mc.name).includes(:user)
      end
      records.each do |mod|
        @existing_moderations[mc.name][mod.assessable_id] = mod unless @existing_moderations[mc.name].has_key?(mod.assessable_id) && @existing_moderations[mc.name][mod.assessable_id].user_id == current_user.id
      end
    end

    render 'assessable/index'
  end

  # create a new moderation
  def create
    authorize! :create, Assessable::Assessment

    #params[:moderate][:status] = Assessable::Assessment.STATUSES.index(params[:moderate].delete(:moderation_status))
    params[:moderate][:user_id] = current_user.id
    params[:moderate][:account_id] = current_tenant.id

    moderation = Assessable::Assessment.where(:assessable_type => params[:moderate][:assessable_type], :assessable_id => params[:moderate][:assessable_id], :user_id => current_user.id).first
    
    if moderation
      moderation.status = params[:moderate][:status]
      moderation.save
    else
      moderation = Assessable::Assessment.create!(params[:moderate])
    end

    assessable = moderation.root_object
    assessable.moderation_status = moderation.status
    assessable.save

    render :json => {:success => true}.to_json
  end

end