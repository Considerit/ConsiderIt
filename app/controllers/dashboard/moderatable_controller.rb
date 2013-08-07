class Dashboard::ModeratableController < Dashboard::DashboardController

  rescue_from CanCan::AccessDenied do |exception|
    result = {
      :result => 'failed',
      :reason => current_user.nil? ? 'not logged in' : 'not authorized'
    }
    render :json => result
  end

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    authorize! :index, Moderation

    if !current_tenant.enable_moderation
      redirect_to root_path, :notice => "Moderation is disabled for this application."
      return
    end

    moderatable_classes = []
    @classes_to_moderate = Moderation.classes_to_moderate

    @existing_moderations = {}
    @objs_to_moderate = {}
    @classes_to_moderate.each do |mc|
      class_name = mc.name.split('::')[-1]

      moderatable_classes.push({ :name => class_name, :text_fields => mc.text_fields })

      @existing_moderations[class_name] = {}

      if mc == Commentable::Comment
        # Assumes Commentable_type is Point!!!
        # select all comments of points of active proposals
        qry = "SELECT c.id, c.body AS body, pnt.id AS root_id, prop.long_id AS proposal_id FROM comments c, points pnt, proposals prop WHERE prop.account_id=#{current_tenant.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.commentable_id=pnt.id"
      elsif mc == Point
        qry = "SELECT pnt.id, pnt.nutshell AS nutshell, pnt.text AS text, prop.long_id AS proposal_id FROM points pnt, proposals prop WHERE prop.account_id=#{current_tenant.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
      end
      objects = ActiveRecord::Base.connection.select(qry)

      @objs_to_moderate[class_name] = objects
      objs = @objs_to_moderate[class_name].map{|x| x["id"]}.compact

      records = Moderation.where(:moderatable_type => mc.name)
      if objs.length > 0
        records = records.where("moderatable_id in (#{objs.join(',')})")
      end
      records = records.includes(:user)

      records.select([:user_id, :id, :status, :moderatable_id]).each do |mod|
        @existing_moderations[class_name][mod.moderatable_id] = mod unless @existing_moderations[class_name].has_key?(mod.moderatable_id) && @existing_moderations[class_name][mod.moderatable_id].user_id == current_user.id
      end
    end

    rendered_admin_template = params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil

    render :json => {:objs_to_moderate => @objs_to_moderate, :classes_to_moderate => moderatable_classes, :existing_moderations => @existing_moderations, :admin_template => rendered_admin_template}
  end

  # create a new moderation
  def create
    authorize! :create, Moderation

    #params[:moderate][:status] = Moderation.STATUSES.index(params[:moderate].delete(:moderation_status))
    params[:moderate][:user_id] = current_user.id
    params[:moderate][:account_id] = current_tenant.id

    moderation = Moderation.where(:moderatable_type => params[:moderate][:moderatable_type], :moderatable_id => params[:moderate][:moderatable_id], :user_id => current_user.id).first
    
    if moderation
      moderation.status = params[:moderate][:status]
      moderation.save
    else
      moderation = Moderation.create!(params[:moderate])
    end

    moderatable = moderation.root_object
    moderatable.moderation_status = moderation.status
    moderatable.save

    render :json => {:success => true}.to_json
  end

end