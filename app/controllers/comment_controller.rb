
class CommentController < ApplicationController
  protect_from_forgery

  respond_to :json

  def create
    authorize! :create, Comment

    commentable_id = params[:comment][:commentable_id]
    commentable_type = params[:comment][:commentable_type]

    comment = Comment.where(:commentable_id => commentable_id).where(:commentable_type => commentable_type).find_by_body(params[:comment][:body])

    if comment.nil?
      commentable = commentable_type.constantize.find commentable_id
      comment = Comment.build_from(commentable, current_user.id, params[:comment][:body] )

      #TODO: implement this as instrumentation
      if commentable_type == 'Point'
        commentable.comment_count = commentable.comments.count
        commentable.save
      end

      if comment.save

        ActiveSupport::Notifications.instrument("comment:#{commentable_type.downcase}:created", 
          :commentable => commentable,
          :comment => comment, 
          :current_tenant => current_tenant,
          :mail_options => mail_options
        )

        #TODO: implement this as instrumentation        
        comment.track!
        comment.follow!(current_user, :follow => true, :explicit => false)

        if commentable.respond_to? :follow!
          commentable.follow!(current_user, :follow => true, :explicit => false)
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

    comment.update_attributes! update_attributes.permit(:body)

    commentable = comment.root_object

    ActiveSupport::Notifications.instrument("comment:#{comment.commentable_type}:updated", 
      :model => comment, 
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    render :json => comment

  end





end