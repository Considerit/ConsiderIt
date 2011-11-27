class Reflect::ReflectBulletRevision < ActiveRecord::Base
  belongs_to :comment
  belongs_to :user

  belongs_to :bullet, :class_name => 'ReflectBullet', :foreign_key => 'bullet_id'  
  has_many :highlights, :class_name => 'ReflectHighlight', :foreign_key => 'bullet_rev'
  has_many :responses, :class_name => 'ReflectResponseRevision', :foreign_key => 'bullet_rev'
  
  default_scope where( :active => true )

  #TODO
  def notify_parties(send = APP_CONFIG['send_email'])
  #   user = comment.user
  #   sent_to = {}
  #   if user.user_mailer_preferences.point_summarized
  #     if send
  #       Notifier.deliver_someone_summarized_your_comment(comment.find_commentable, self, user)
  #     end
  #     sent_to[user.id] = user.name
  #   end
  #   return sent_to
  end
end
