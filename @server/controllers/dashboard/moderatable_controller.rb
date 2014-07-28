class Dashboard::ModeratableController < Dashboard::DashboardController

  # list all the objects to be moderated; allow seeing the existing moderations
  def index
    authorize! :index, Moderation

    # if !current_tenant.enable_moderation
    #   redirect_to root_path, :notice => "Moderation is disabled for this application."
    #   return
    # end

    moderatable_classes = []
    classes_to_moderate = current_tenant.classes_to_moderate   

    @existing_moderations = {}
    objs_to_moderate = {}
    classes_to_moderate.each do |mc|
      class_name = mc.name.split('::')[-1]

      moderatable_classes.push({ :name => class_name, :text_fields => mc.moderatable_fields })

      @existing_moderations[class_name] = {}

      if mc == Comment
        # Assumes Commentable_type is Point!!!
        # select all comments of points of active proposals
        qry = "SELECT c.id, c.user_id, c.body AS body, pnt.id AS root_id, prop.long_id AS proposal_id FROM comments c, points pnt, proposals prop WHERE prop.account_id=#{current_tenant.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND c.commentable_id=pnt.id"
      elsif mc == Proposal
        qry = "SELECT id, long_id, user_id, name, description, additional_description1, additional_description2 from proposals where account_id=#{current_tenant.id}"
      elsif mc == Point
        qry = "SELECT pnt.id, pnt.long_id, pnt.user_id, pnt.nutshell AS nutshell, pnt.text AS text, prop.long_id AS proposal_id FROM points pnt, proposals prop WHERE prop.account_id=#{current_tenant.id} AND prop.active=1 AND prop.id=pnt.proposal_id AND pnt.published=1"
      end
      objects = ActiveRecord::Base.connection.select(qry)

      objs_to_moderate[class_name] = objects
      objs = objs_to_moderate[class_name].map{|x| x["id"]}.compact

      records = Moderation.where(:moderatable_type => mc.name)
      if objs.length > 0
        records = records.where("moderatable_id in (#{objs.join(',')})")
        records = records.includes(:user)

        records.select([:user_id, :id, :status, :moderatable_id, :moderatable_type, :updated_since_last_evaluation, :notification_sent]).each do |mod|
          @existing_moderations[class_name][mod.moderatable_id] = mod unless @existing_moderations[class_name].has_key?(mod.moderatable_id) && @existing_moderations[class_name][mod.moderatable_id].user_id == current_user.id
        end
        
      end

      @existing_moderations[class_name] = @existing_moderations[class_name].values

    end

    rendered_admin_template = params["admin_template_needed"] == 'true' ? self.process_admin_template() : nil

    @dash_data = {:objs_to_moderate => objs_to_moderate, :classes_to_moderate => moderatable_classes, :existing_moderations => @existing_moderations, :admin_template => rendered_admin_template}
    
    if request.xhr?
      render :json => @dash_data 
    else
      render "layouts/dash", :layout => false 
    end


  end

  # create a new moderation
  def create
    authorize! :create, Moderation

    #params[:moderate][:status] = Moderation.STATUSES.index(params[:moderate].delete(:moderation_status))
    params[:moderate][:user_id] = current_user.id
    params[:moderate][:account_id] = current_tenant.id

    moderation = Moderation.where(:moderatable_type => params[:moderate][:moderatable_type], :moderatable_id => params[:moderate][:moderatable_id]).last
    
    if moderation
      update_attrs = { 
        :user_id => params[:moderate][:user_id],
        :status => params[:moderate][:status],
        :updated_since_last_evaluation => false } 
      moderation.update_attributes! ActionController::Parameters.new(update_attrs).permit!        
    else
      moderation = Moderation.create!(params[:moderate].permit!)
    end

    if !moderation.notification_sent && moderation.status == 1
      ActiveSupport::Notifications.instrument("moderation:#{moderation.moderatable_type.downcase}:passed", 
        :model => moderation.root_object,
        :current_tenant => current_tenant,
        :mail_options => mail_options
      )      

      moderation.notification_sent = true
      moderation.save
    end

    moderatable = moderation.root_object
    moderatable.moderation_status = moderation.status
    moderatable.save

    render :json => {:result => 'success', :moderation => moderation}
  end

end


def handle_moderatable_model_update(model)
  model.moderations.each do |mod|
    mod.updated_since_last_evaluation = true
    mod.save
  end
end

ActiveSupport::Notifications.subscribe("proposal:updated") do |*args|
  handle_moderatable_model_update args.last[:model]
end

ActiveSupport::Notifications.subscribe("point:updated") do |*args|
  handle_moderatable_model_update args.last[:model]
end

ActiveSupport::Notifications.subscribe("comment:updated") do |*args|
  handle_moderatable_model_update args.last[:model]
end
