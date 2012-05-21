
class Reflect::ReflectResponseController < ApplicationController
  respond_to :json
  
  def create
    bullet_obj, bullet_rev = get_current_bullet
    
    if has_permission?('add', current_user, bullet_obj, bullet_rev)
      json_response = add_or_update(bullet_obj, bullet_rev)
    else
      json_response = ''.to_json
    end
    
    render :json => json_response

  end
  
  def update
    response_rev = Reflect::ReflectResponseRevision.find_by_response_id(params[:response_id])
    if response_rev
      response_obj = response_rev.response
    else
      raise 'Could not find response with that id'
    end
    
    bullet_obj, bullet_rev = get_current_bullet
    
    if has_permission?('add', current_user, bullet_obj, bullet_rev, response_obj, response_rev) 
      json_response = add_or_update( response_obj, response_rev )
    else
      json_response = ''.to_json
    end
    
    render :json => json_response
  end
  
  def destroy
    response_rev = Reflect::ReflectResponseRevision.find_by_response_id(params[:response_id])
    if response_rev
      response_obj = response_rev.response
    else
      raise 'Could not find response with that id'
    end
    cur_bullet, bullet_rev = get_current_bullet
    
    if has_permission?('delete', current_user, cur_bullet, bullet_rev, response_obj, response_rev)
      response_obj.destroy  
    end

    render :nothing => true
  end
  
  protected

  def get_current_bullet
    bullet_rev = Reflect::ReflectBulletRevision.find_by_bullet_id(params[:bullet_id])
    if bullet_rev
      bullet_obj = bullet_rev.bullet
    else
      raise 'Could not find bullet with that id'
    end   
    return bullet_obj, bullet_rev
  end
  
  def has_permission?(verb, user, cur_bullet, bullet_rev, cur_response = nil, response_rev = nil)
    comment = bullet_rev.comment
    commentAuthor = comment.user
    
    if current_user.nil?
      userLevel = -1
    else
      userLevel = user.admin ? 1 : 0
    end
                    
    denied =    ( # only admins and response authors can delete responses
                    verb == 'delete' \
                    && commentAuthor.id != user.id \
                    && userLevel < 1
                ) \
            ||    ( # only comment authors can add responses
                    verb == 'add' \
                    && commentAuthor.id != user.id
                )
    return !denied
  end
  
  def add_or_update( cur_bullet, bullet_rev, response_obj = nil, response_rev = nil)
    user = current_user
  
    signal = params[:signal].to_i
    
    text = params[:text]
    
    modify = !response_obj.nil?
    
    new_rev = Reflect::ReflectResponseRevision.new(
       :bullet_id => cur_bullet.id,
       :bullet_rev => bullet_rev.id,
       :user => user,
       :signal => signal,
       :text => text
    )

    if modify
      new_rev.response_id = response_obj.id
      response_rev.active = false
    else
      response_obj = Reflect::ReflectResponse.create(
         :bullet_id => cur_bullet.id,
      )
      new_rev.response_id = response_obj.id
    end
    
    new_rev.save
    if modify
      new_rev.notify_parties(current_tenant, default_url_options)
    end

    return {:insert_id => response_obj.id, :rev_id => new_rev.id, :u => user.name, :sig => signal}.to_json

  end




end
