class Reflect::ReflectResponseRevision < ActiveRecord::Base
  belongs_to :bullet, :class_name => 'ReflectBulletRevision', :foreign_key => 'bullet_id'
  belongs_to :bullet_revision, :class_name => 'ReflectBulletRevision', :foreign_key => 'bullet_rev'
  belongs_to :user
  
  belongs_to :response, :class_name => 'ReflectResponse', :foreign_key => 'response_id'
  
  default_scope where( :active => true )
  
  # TODO
  def notify_parties(send = APP_CONFIG['send_email'])
  #   user = bullet_revision.user
  #   sent_to = {}
  #   if user.user_mailer_preferences.summary_response
  #     if signal == 0
  #       judgement = 'off target'
  #     elsif signal == 1
  #       judgement = 'not quite right'
  #     elsif signal == 2
  #       judgement = 'on target'
  #     end          
  #     if send
  #       Notifier.deliver_someone_responded_to_your_summary(bullet_revision.comment.find_commentable, self, user, judgement)
  #     end  
  #     sent_to[user.id] = user.name
  #   end
  #   return sent_to
  end
    
end