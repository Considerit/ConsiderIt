class Activity < ActiveRecord::Base
  acts_as_tenant(:account)

  belongs_to :action, :polymorphic=>true
  belongs_to :user

  def self.build_from!(object)
    return nil if object.account_id.nil?

    if object.class.name != 'User'
      existing = Account.find(object.account_id).activities.where(:action_type => object.class.name, :action_id => object.id, :user_id => object.user_id).first
      if existing
        existing.destroy
      end
    end
    a = self.new
    a.action_id = object.id 
    a.action_type = object.class.name 
    if object.class.name != 'User'
      a.user_id = object.user_id
    end
    a.account_id = object.account_id
    a.created_at = object.created_at
    a.save
    a
  end

  def obj
    begin
      return action_type.constantize.find(action_id)
    rescue
    end
    return nil

  end  

  def title
    this_obj = obj
    return 'Could not find Object' if !this_obj
    case action_type
    when 'Proposal'
      if user
        "#{user.username} contributed a new proposal"
      else
        "New proposal added"
      end
    when 'Point'
      "#{user ? user.username : 'Anonymous'} wrote a new point for \"#{this_obj.proposal.title}\""
    when 'Position'
      "#{user ? user.username : 'Anonymous'} #{this_obj.stance_name_singular} \"#{this_obj.proposal.title}\""
    when 'Inclusion'
      "#{user ? user.username : 'Anonymous'} included a point by #{this_obj.point.hide_name || !this_obj.point.user ? '[hidden]' : this_obj.point.user.username} for \"#{this_obj.proposal.title}\""
    when 'Reflect::ReflectBulletRevision'
      "#{user ? user.username : 'Anonymous'} summarized a comment by #{this_obj.comment.user.username}"
    when 'Comment'
      #TODO: handle commentable type
      "#{user ? user.username : 'Anonymous'} commented on an {item} by #{this_obj.root_object.user.username} for \"#{this_obj.root_object.proposal.title}\""      
    when 'User'
      "Welcome to #{this_obj.name}!"      
    else
      raise "Don't know about this"
    end
  end

  def description
    this_obj = obj
    return 'Could not find Object' if !this_obj

    case action_type
    when 'Proposal'
      "\"#{this_obj.title}\"."
    when 'Point'
      "\"#{this_obj.nutshell}\"."
    when 'Position'
      ""
    when 'Inclusion'
      "The point states \"#{this_obj.point.nutshell}\". #{this_obj.point.inclusions.count - 1} others have included this point."
    when 'Reflect::ReflectBulletRevision'
      "#{user ? user.username : 'Anonymous'} believes that #{this_obj.comment.user.username} said \"#{this_obj.text}\"."
    when 'Comment'
      #TODO: handle commentable
      "#{user.username} commented on an {item} by #{this_obj.root_object.hide_name || !this_obj.root_object.user ? '[hidden]' : this_obj.root_object.user.username} for \"#{this_obj.root_object.proposal.title}\""      
    when 'User'
      "#{this_obj.account.users.where('created_at < \' ' + created_at.to_s + '\'').count } other people have joined."      
    else
      raise "Don't know about this"
    end
  end

  #TODO: get commentable path
  def url(host)
    helper = Rails.application.routes.url_helpers

    case action_type
    when 'Proposal'
      helper.proposal_url(obj.long_id, :host => host)
    when 'Point'
      helper.proposal_point_url(obj.proposal.long_id, obj.id, :host => host)
    when 'Position'
      ""
    when 'Inclusion'
      helper.proposal_point_url(obj.proposal.long_id, obj.point_id, :host => host)
    when 'Reflect::ReflectBulletRevision'
      #obj.comment.commentable_path
      helper.proposal_url(obj.comment.root_object.proposal.long_id, :host => host)
    when 'Comment'
      #obj.comment.commentable_path
      helper.proposal_url(obj.root_object.proposal.long_id, :host => host)
    when 'User'
      helper.root_url(:host => host)  
    else
      raise "Don't know about this"
    end
  end

end