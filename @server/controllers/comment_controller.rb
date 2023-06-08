
class CommentController < ApplicationController

  def all_for_subdomain
    dirty_key '/all_comments'

    render :json => []
  end 


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
    fields = ['body', 'hide_name']
    comment = params.select{|k,v| fields.include? k}.to_h

    comment['user_id'] = current_user && current_user.id || nil
    comment['subdomain_id'] = current_subdomain.id
    comment['point'] = Point.find(key_id(params['point']))

    point = comment['point']

    comment = Comment.new comment
    
    authorize! 'create comment', comment

    if comment.save

      Notifier.notify_parties('new', comment)
      comment.notify_moderator

      original_id = key_id(params[:key])
      result = comment.as_json
      result['key'] = "/comment/#{comment.id}?original_id=#{original_id}"
      dirty_key "/comments/#{point.id}"

      point.set_comment_count
      dirty_key "/point/#{point.id}"  

      current_user.update_subscription_key(point.proposal.key, 'watched', :force => false)
      dirty_key "/current_user"
      
    else 
      result = {key: params[:key], errors: ['Comment could not be saved']}
    end

    render :json => [result]     

  end

  def update
    comment = Comment.find(params[:id])
    authorize! 'update comment', comment

    fields = ['body', 'hide_name']
    comment_vals = params.select{|k,v| fields.include? k}.to_h

    comment.update! comment_vals

    comment.redo_moderation

    dirty_key "/comment/#{comment.id}"
    render :json => []

  end

  def destroy
    comment = Comment.find params[:id]
    authorize! 'delete comment', comment

    comment.destroy

    point = comment.point
    point.set_comment_count
    point.save

    dirty_key "/point/#{point.id}"
    dirty_key("/comments/#{point.id}")

    render :json => []
  end

end
