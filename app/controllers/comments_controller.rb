
class CommentsController < ApplicationController
  protect_from_forgery

  respond_to :json

  def create
    authorize! :create, Comment

    commentable_id = params[:comment][:commentable_id]
    commentable_type = params[:comment][:commentable_type]

    commentable = commentable_type.constantize.find commentable_id

    comment = Comment.where(:commentable_id => commentable_id).where(:commentable_type => commentable_type).find_by_body(params[:comment][:body])

    is_new = comment.nil?

    if is_new
      comment = Comment.build_from(commentable, current_user.id, params[:comment][:body] )
      if commentable_type == 'Point'
        commentable.comment_count = commentable.comments.count
        commentable.save
      end
    end

    if comment.save
      if is_new

        ActiveSupport::Notifications.instrument("new_comment_on_#{commentable_type}", 
          :commentable => commentable,
          :comment => comment, 
          :current_tenant => current_tenant,
          :mail_options => mail_options
        )

        #comment.notify_parties(current_tenant, mail_options)
        comment.track!
        comment.follow!(current_user, :follow => true, :explicit => false)
        if commentable.respond_to? :follow!
          commentable.follow!(current_user, :follow => true, :explicit => false)
        end
      end

      #follows = commentable.follows.where(:user_id => current_user.id).first

      #response = { :new_point => new_comment, :comment_id => @comment.id, :is_following => follows && follows.follow }

      render :json => comment     
    end

  end

  def update
    comment = Comment.find(params[:id])
    authorize! :update, Comment

    update_attributes = {
      :body => params[:comment][:body]
    }

    comment.update_attributes!(update_attributes)

    render :json => comment

  end



end