class Reflect::ReflectResponseRevision < ActiveRecord::Base
  belongs_to :bullet, :class_name => 'ReflectBullet', :foreign_key => 'bullet_id'
  belongs_to :bullet_revision, :class_name => 'ReflectBulletRevision', :foreign_key => 'bullet_rev'
  belongs_to :user
  
  belongs_to :response, :class_name => 'ReflectResponse', :foreign_key => 'response_id'
  
  default_scope where( :active => true )

  def notify_parties
    message_sent_to = {}
    bulleter = bullet_revision.user
    pp 'notifying parties'

    pp bulleter.email
    pp bulleter.notification_responder
    
    if bulleter.notification_responder && bulleter.email.length > 0
      UserMailer.your_reflection_was_responded_to(bulleter, self, bullet_revision, bullet_revision.comment)
      message_sent_to[bulleter.id]
    end

    return message_sent_to
  end  
    
end