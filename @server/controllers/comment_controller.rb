
class CommentController < ApplicationController
  protect_from_forgery

  respond_to :json

  def index

    point = Point.find params[:point_id]
    authorize! :read, point

    # Getting all comments. Remember that there are multiple types of comments: straight comments and expert review comments
    #todo: make this more efficient and natural
    
    response = {
      :comments => point.comments,
      :key => "/comments/#{point.id}"
    }

    if current_tenant.assessment_enabled
      response.update({
        :assessment => point.assessment && point.assessment.complete ? point.assessment.public_fields : nil,
        :verdicts => Assessable::Verdict.all,
        :claims => point.assessment && point.assessment.complete ? point.assessment.claims.public_fields : nil,
        :already_requested_assessment => current_user && Assessable::Request.where(:assessable_id => point.id, :assessable_type => 'Point', :user_id => current_user.id).count > 0
      })
    end

    respond_to do |format|
      format.json {render :json => response}
    end
  end

  def create
    authorize! :create, Comment

    commentable_id = params[:comment][:commentable_id]
    commentable_type = params[:comment][:commentable_type]

    comment = Comment.where(:commentable_id => commentable_id).where(:commentable_type => commentable_type).find_by_body(params[:comment][:body])

    if comment.nil?
      commentable = commentable_type.constantize.find commentable_id
      comment = Comment.build_from(commentable, current_user.id, params[:comment][:body] )

      if comment.save

        ActiveSupport::Notifications.instrument("comment:point:created", 
          :commentable => commentable,
          :comment => comment, 
          :current_tenant => current_tenant,
          :mail_options => mail_options
        )

        # comment.follow!(current_user, :follow => true, :explicit => false)

        if commentable.respond_to? :follow!
          commentable.follow!(current_user, :follow => true, :explicit => false)
        end

        if commentable.respond_to? :comment_count 
          commentable.comment_count = commentable.comments.count
          commentable.save
        end

      end

    end
    render :json => comment     

  end

  def update
    comment = Comment.find(params[:id])
    authorize! :update, Comment

    update_attributes = {
      :body => params[:comment][:body]
    }

    comment.update_attributes! ActionController::Parameters.new(update_attributes).permit(:body)

    ActiveSupport::Notifications.instrument("comment:point:updated", 
      :model => comment, 
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    render :json => comment

  end

end

