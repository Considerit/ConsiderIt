class Reflect::ReflectResponseRevision < ActiveRecord::Base
  belongs_to :bullet, :class_name => 'Reflect::ReflectBullet', :foreign_key => 'bullet_id'
  belongs_to :bullet_revision, :class_name => 'Reflect::ReflectBulletRevision', :foreign_key => 'bullet_rev'
  belongs_to :user
  
  belongs_to :response, :class_name => 'Reflect::ReflectResponse', :foreign_key => 'response_id'
  acts_as_tenant(:account)
  
  default_scope where( :active => true )

  def notify_parties(current_tenant, options)
    message_sent_to = {}
    bulleter = bullet_revision.user
    position = get_position_for_user(bullet_revision.comment, bulleter)

    if bulleter.notification_author && bulleter.email.length > 0
      UserMailer.delay.your_reflection_was_responded_to(bulleter, self, bullet_revision, bullet_revision.comment, options)
      message_sent_to[bulleter.id]
    end

    return message_sent_to
  end  

  def get_position_for_user(comment, user)
    obj = comment.root_object
    commentable_type = comment.commentable_type

    if commentable_type == 'Point' 
      user.positions.published.find_by_proposal_id(obj.proposal_id)
    elsif commentable_type == 'Position'
      if user.id == obj.user_id
        obj
      else
        user.positions.published.find_by_proposal_id(obj.proposal_id)
      end
    end
  end    
    
end