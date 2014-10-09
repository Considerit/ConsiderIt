
class CommentController < ApplicationController
  protect_from_forgery

  respond_to :json

  def index

    point = Point.find params[:point_id]
    authorize! :read, point

    dirty_key "/comments/#{point.id}"

    render :json => []
  end

  def create
    authorize! :create, Comment

    fields = ['body']
    comment = params.select{|k,v| fields.include? k}

    comment['user_id'] = current_user && current_user.id || nil
    comment['account_id'] = current_tenant.id
    comment['point'] = Point.find(key_id(params['point']))

    # don't allow repeat comments
    existing_comment = Comment.where(:point_id => comment['point_id']).find_by_body(comment['body'])

    if existing_comment.nil?
      point = comment['point']

      comment = Comment.new comment

      if comment.save
        ActiveSupport::Notifications.instrument("comment:point:created", 
          :comment => comment, 
          :current_tenant => current_tenant,
          :mail_options => mail_options
        )

        original_id = key_id(params[:key])
        result = comment.as_json
        result['key'] = "/comment/#{comment.id}?original_id=#{original_id}"
        remap_key(params[:key], "/comment/#{comment.id}")
        dirty_key "/comments/#{point.id}"

        point.follow!(current_user, :follow => true, :explicit => false)

        point.comment_count = point.comments.count
        point.save
      else 
        result = {errors: ['could not save comment']}
      end

    else 
      result = existing_comment
    end

    render :json => [result]     

  end

  def update
    comment = Comment.find(params[:id])
    authorize! :update, Comment

    fields = ['body']
    comment_vals = params.select{|k,v| fields.include? k}

    comment.update_attributes! comment_vals


    ActiveSupport::Notifications.instrument("comment:point:updated", 
      :model => comment, 
      :current_tenant => current_tenant,
      :mail_options => mail_options
    )

    dirty_key "/comment/#{comment.id}"
    render :json => []

  end

  def destroy
    comment = Comment.find params[:id]
    authorize! :destroy, comment

    dirty_key("/comments/#{comment.point_id}")
    comment.destroy

    render :json => []
  end

end
