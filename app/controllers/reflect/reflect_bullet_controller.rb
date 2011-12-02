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
        :response => res
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
    if modify
      new_rev.notify_parties
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
    render :text => '<script type="text/html" id="reflect_template_bullet">
<![CDATA[
  <div class="bullet_main">        

    <div class="bullet_text">
      <div class="bullet_point">&#8226;</div>
      <span class="rf_bullet_text">
        <%= this.bullet_text %> 
      </span>
      <a class="user"> <%= this.user %></a>
    </div> 
    <% if (this.enable_actions) { %>      
      <ul class="bullet_meta">
        <li class="modify_operation" title="Edit this summary bullet point">
          <button class="modify bullet_operation button_as_link op">
            edit
          </button>
        </li>
        <li title="Delete this summary bullet point" class="delete_operation">
          <button class="delete bullet_operation button_as_link op"> 
            delete
          </button>
          <span class="verification">
            Are you sure?
            <a class="delete_for_sure bullet_operation op"> 
              yes
            </a>
            <a class="delete_nope bullet_operation button_as_link op"> 
              no
            </a>              
          
          </span>

          
        </li>
      </ul>
    <% } %>
    
  <div class="bullet_author rf_listener_pic">
    <img title="<%= this.user %>" src="<%= this.listener_pic %>"/>
  </div>    
 </div>
 <div class="rf_evaluation">
   <ul class="badges">
     <div class="cl"></div>
   </ul>
 </div>
 <div class="cl"></div>
]]>
</script>

<script type="text/html" id="reflect_template_ratings_gallery">
<![CDATA[
  <% if (this.enable_rating) { %>
    <li class="rf_rating">
      <ul>
        <li class="rf_gallery_container <%= this.rating %>">
          <div><% if (!this.rating) { %>[]<% } %></div>
        </li>
        <li class="rf_selector_container">
          <% if (this.commenter!=this.logged_in_user) { %> <div class="rf_selector"></div> <% } %>
        </li>
      </ul>
      <div class="cl"></div>
    </li>
  <% } %>
]]>
</script>

<script type="text/html" id="reflect_template_new_bullet_prompt">
<![CDATA[
  <div class="bullet_main">   
    <div class="prompt">
      <div class="bullet_point">&#8226;</div>
       <button class="add_bullet button_as_link" type="button" title="Show you understand by summarizing a point <%= this.commenter %> makes.">   
          <%= this.bullet_prompt %>
       </button>
    </div>
  </div>
  <div class="cl"></div>
]]>
</script>


<script type="text/html" id="reflect_template_bullet_rating">
<![CDATA[
  <div class="rate_bullet <% if (this.logged_in_user == "Anonymous") { %> anon <% } else if (this.logged_in_user == this.bullet_author) { %>self<% } else { %> not_anon <% } %>">
    <form name="rate_bullet" class="rate_bullet_dialog">
      <div class="rate_header">
        Does <%= this.bullet_author %>&#39;s summary...
      </div>
      <div name="zen" class="flag <% if(this.rating == "zen"){ %> selected <% } %>">
        <div class="rating_class zen"></div>
        <div class="label">
          elegantly distill meaning? 
        </div>
        <div class="rating_votes"><span class="others"><%= this.ratings.zen %></span><span class="me">+1</span></div> 
        <div class="cl"></div>            
      </div>
      <div name="gold" class="flag <% if(this.rating == "gold"){ %> selected <% } %>">
        <div class="rating_class gold"></div>
        <div class="label">
          uncover a good point?
        </div>
        <div class="rating_votes"><span class="others"><%= this.ratings.gold %></span><span class="me">+1</span></div>
        <div class="cl"></div>     
      </div>
      <div name="sun" class="flag <% if(this.rating == "sun"){ %> selected <% } %>">
        <div class="rating_class sun"></div>
        <div class="label">                          
          clarify the message?
        </div>
        <div class="rating_votes"><span class="others"><%= this.ratings.sun %></span><span class="me">+1</span></div>
        <div class="cl"></div>     
      </div>
      <div name="troll" class="flag <% if(this.rating == "troll"){ %> selected <% } %>">
        <div class="rating_class troll"></div>
        <div class="label">
          provoke unnecessarily? 
        </div>
        <div class="rating_votes"><span class="others"><%= this.ratings.troll %></span><span class="me">+1</span></div>
        <div class="cl"></div>     
      </div>
      <div name="graffiti" class="flag <% if(this.rating == "graffiti"){ %> selected <% } %>">
        <div class="rating_class graffiti"></div>
        <div class="label">
          umm, its not a summary 
        </div>
        <div class="rating_votes"><span class="others"><%= this.ratings.graffiti %></span><span class="me">+1</span></div>
        <div class="cl"></div>     
      </div>
                                                             
    </form>
    <div class="bullet_id hide"><%= this.bullet_id %></div>
    <% if (this.logged_in_user == "Anonymous") { %> <div class="anon_restrict">Log in to rate this summary</div> <% }
    else if (this.logged_in_user == this.bullet_author) { %> <div class="anon_restrict">Sorry, you can&#39;t judge your own!</div> <% } %>    
  </div>
]]>
</script>

<script type="text/html" id="reflect_template_new_bullet_dialog">
<![CDATA[
  <div class="bullet_main">      
    <div class="rf_dialog">
       <div class="bullet_point">&#8226;</div>
       <div class="new_bullet_text_wrap">
          <textarea class="new_bullet_text" title="Help others better understand and show <%= this.commenter %> that s/he is being heard by restating a point you hear them making."><% if (this.txt) %><%= this.txt %></textarea>  
       </div>
       <ul class="submit_footer">
          <li class="submit">
             <button class="bullet_submit button_as_link" disabled="<% if (this.txt) { %>false<% } else { %>true<% } %>">Done</button>
          </li>
          <li class="submit">
            <a class="cancel_bullet">cancel</a>
          </li>
          <li title="Please limit your summary to 140 characters or less." class="count">
             <a><span class="count"></span></a>
          </li>                
          <li class="be_neutral">
            <a title="Please be concise, accurate, and constructive!">
              <span class="big_word">summaries</span>, not replies 
            </a>
          </li>                  
       </ul>
    </div>
  </div>
  <div class="cl"></div>
]]>
</script>

<script type="text/html" id="reflect_template_bullet_highlight">
<![CDATA[
      <div class="new_bullet_text_wrap connect_directions">
        <div class="arrow">&#8592;</div>
        Please click the relevant sentences
      </div>
      <ul class="submit_footer">
         <li class="submit">
            <button class="bullet_submit button_as_link">Done</button>
         </li>
        <li class="submit">
          <a class="cancel_bullet">cancel</a>
        </li>          
      </ul>
]]>
</script>


<script type="text/html" id="reflect_template_response">
<![CDATA[
  <% if(this.sig == "2") { %>
    <span class="rf_response_symbol confirmed">&#10003;</span> 
  <% } else if(this.sig == "0") { %>
    <span class="rf_response_symbol not">&#10007;</span>
  <% } %>
]]>
</script>

<script type="text/html" id="reflect_template_response_prompt">
<![CDATA[
      <div class="response_prompt">
         <div class="floating_arrow">&#9650;</div>
         <label class="prompt"><%= this.response_prompt %></label>
         <span class="action_call">click to answer</span>
         <ul class="response_eval">
            <li><input type="radio" id="accurate-yes-<%=this.bullet_id %>" name="accurate-<%=this.bullet_id %>" value="2" <% if(this.sig == "2"){ %> CHECKED <% } %>><label for="accurate-yes-<%=this.bullet_id %>" class="response_yes">Yes.</label></li>
            <li><input type="radio" class="response_maybe" id="accurate-maybe-<%=this.bullet_id %>" name="accurate-<%=this.bullet_id %>" value="1" <% if(this.sig == "1"){ %> CHECKED <% } %>><label for="accurate-maybe-<%=this.bullet_id %>" class="response_maybe">Perhaps, but I should clarify...</label>

            <div class="response_dialog">
              <div class="rf_dialog">
                <div class="new_bullet_text_wrap">
                  <textarea class="new_response_text" title="Clarify your point to help <%=this.summarizer %> and others better understand your message."><% if(this.text) %><%= this.text %></textarea>
                </div>
                <ul><li title="Please limit your response to 140 characters or less." class="count">
                  <a>
                    <span class="count"></span>
                  </a>
                </li>
                </ul>
              </div>
            </div>            
            
            </li>
            <li><input type="radio" id="accurate-no-<%=this.bullet_id %>" name="accurate-<%=this.bullet_id %>" value="0" <% if(this.sig == "0"){ %> CHECKED <% } %>><label for="accurate-no-<%=this.bullet_id %>" class="response_no">Huh? This isn&#39;t a summary.</label></li>

            <li>
              <div class="rf_dialog">
                <ul class="submit_footer">
                  <li class="submit">
                    <button class="bullet_submit button_as_link">Done</button>
                  </li>
                  <li class="submit">
                    <a class="cancel_bullet">cancel</a>
                  </li>                 
                </ul>
              </div>            
            </li>
         </ul>

         
      </li>
      </div>
      

]]>
</script>
<div id="reflect_templates_present"></div>'
  end
end
