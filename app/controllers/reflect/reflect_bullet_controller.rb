require 'json'

class Reflect::ReflectBulletController < ApplicationController
  respond_to :json
  
  def index
    comments = JSON.parse(params[:comments].gsub('\\',''))
    data = {}
    
    db_bullets = Reflect::ReflectBulletRevision.all( :conditions => { :comment_id => comments } )

    db_bullets.each do |db_bullet_rev| 
      db_bullet = db_bullet_rev.bullet

      response = db_bullet.response
      res = response.nil? ? nil : {
         :id => response.response_id.to_s,
         :rev => response.id.to_s,
         :ts => response.created_at.to_s,
         :u => response.user.name,
         :sig => response.signal.to_s,
         :txt => response.text
      }

      highlights = []
      db_bullet_rev.highlights.each do |hi|
        highlights.push( hi.element_id )
      end

      bullet = {
        :id => db_bullet_rev.bullet_id.to_s,
        :ts => db_bullet_rev.created_at.to_s,
        :u => db_bullet_rev.user.nil? ? 'Anonymous' : db_bullet_rev.user.name,
        :txt => db_bullet_rev.text,
        :rev => db_bullet_rev.id.to_s,
        :highlights => highlights,
        :response => res,
        :uid => db_bullet_rev.user_id
      }

      if !data.key?(db_bullet.comment_id.to_s)
        data[db_bullet.comment_id.to_s] = {db_bullet_rev.bullet_id.to_s => bullet}
      else
        data[db_bullet.comment_id.to_s][db_bullet_rev.bullet_id.to_s] = bullet
      end
    end
    
    render :json => data.to_json
  end

  def create
    
    if has_permission?('add', current_user)
      json_response = add_or_update()
    else
      json_response = ''.to_json
    end
    render :json => json_response
  end
  
  def update
    cur_bullet, bullet_rev = get_current_bullet
    
    if has_permission?('add', current_user, cur_bullet, bullet_rev) 
      json_response = add_or_update( cur_bullet, bullet_rev )
    else
      json_response = ''.to_json
    end
    render :json => json_response
  end
  
  def destroy
    cur_bullet, bullet_rev = get_current_bullet
    if has_permission?('delete', current_user, cur_bullet, bullet_rev) 
      cur_bullet.destroy
    end
    render :json => ''.to_json
  end
  
  def get_current_bullet
    bullet_rev = Reflect::ReflectBulletRevision.find_by_bullet_id(params[:bullet_id])
    if bullet_rev
      bullet_obj = bullet_rev.bullet
    else
      raise 'Could not find bullet with that id'
    end   
    return bullet_obj, bullet_rev
  end
  
  def has_permission?(verb, user, cur_bullet= nil, bullet_rev = nil)
    
    comment = Comment.find(params[:comment_id])
    commentAuthor = comment.user

    if bullet_rev.nil?
      bulletAuthor = user
    else
      bulletAuthor = bullet_rev.user
    end
    
    if current_user.nil?
      userLevel = -1
    else
      userLevel = user.admin ? 1 : 0
    end
    
    denied =    ( # only admins and bullet authors can delete bullets
                    verb == 'delete' \
                    && bulletAuthor.id != user.id \
                    && userLevel < 1
                ) \
            ||    ( # commenters can't add bullets to their comment
                    verb == 'add' \
                    && userLevel > -1 && commentAuthor.id == user.id
                    )
    return !denied
  end
  
  def add_or_update( bullet_obj = nil, bullet_rev = nil)
    user = current_user
  
    comment_id = params[:comment_id].to_i
    text = params[:text]
    
    if (text == '')
      respond_to do |format|
        format.js  {
          render :json => {}.to_json
        }
      end              
    end
    
    modify = !bullet_obj.nil?
    
    new_rev = Reflect::ReflectBulletRevision.new(
       :comment_id => comment_id,
       :user => user,
       :text => text
    )    

    if modify
      new_rev.bullet_id = bullet_obj.id
      bullet_rev.active = false
    else
      bullet_obj = Reflect::ReflectBullet.new(
         :comment_id => comment_id
      )
      bullet_obj.save
      new_rev.bullet_id = bullet_obj.id  
    end
    
    new_rev.save
    if !modify
      new_rev.notify_parties(current_tenant, default_url_options)
    end
    
    if params.key?(:highlights)
      highlights = JSON.parse(params[:highlights].gsub('\\',''))
      highlights.each do |hi|
        Reflect::ReflectHighlight.create(
         :bullet_id => bullet_obj.id,
         :bullet_rev => new_rev.id,
         :element_id => hi
        )
      end
    end
    
    return {:insert_id => bullet_obj.id, :rev_id => new_rev.id, :u => user.nil? ? 'Anonymous' : user.name}.to_json

  end

  def get_templates
    render :text => ''
  end
end
