
class CommentController < ApplicationController
  respond_to :json

  def index

    point = Point.find params[:point_id]
    authorize! 'read point', point

    dirty_key "/comments/#{point.id}"

    render :json => []
  end

  def show
    comment = Comment.find params[:id]
    authorize! 'read comment', comment

    dirty_key "/comment/#{comment.id}"
    render :json => []
  end

  def create
    fields = ['body']
    comment = params.select{|k,v| fields.include? k}

    comment['user_id'] = current_user && current_user.id || nil
    comment['subdomain_id'] = current_subdomain.id
    comment['point'] = Point.find(key_id(params['point']))

    # don't allow repeat comments
    existing_comment = Comment.where(:point_id => comment['point_id']).find_by_body(comment['body'])

    if existing_comment.nil?
      point = comment['point']

      comment = Comment.new comment
      
      authorize! 'create comment', comment

      if comment.save

        Notifier.create_notification('create', comment)

        original_id = key_id(params[:key])
        result = comment.as_json
        result['key'] = "/comment/#{comment.id}?original_id=#{original_id}"
        dirty_key "/comments/#{point.id}"

        point.follow!(current_user, :follow => true, :explicit => false)

        point.comment_count = point.comments.count
        point.save
        dirty_key "/point/#{point.id}"

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
    authorize! 'update comment', comment

    fields = ['body']
    comment_vals = params.select{|k,v| fields.include? k}

    comment.update_attributes! comment_vals

    comment.redo_moderation

    dirty_key "/comment/#{comment.id}"
    render :json => []

  end

  def destroy
    comment = Comment.find params[:id]
    authorize! 'delete comment', comment

    comment.destroy

    point = comment.point
    point.comment_count = point.comments.count
    point.save

    dirty_key "/point/#{point.id}"
    dirty_key("/comments/#{point.id}")

    render :json => []
  end

end
