class Reflect::ReflectBulletRevision < ActiveRecord::Base
  belongs_to :comment
  belongs_to :user

  belongs_to :bullet, :class_name => 'ReflectBullet', :foreign_key => 'bullet_id'  
  has_many :highlights, :class_name => 'ReflectHighlight', :foreign_key => 'bullet_rev'
  has_many :responses, :class_name => 'ReflectResponseRevision', :foreign_key => 'bullet_rev'
  
  default_scope where( :active => true )

  def notify_parties
    commenter = comment.user
    message_sent_to = {}
    bulleter = user
    if commenter.id != bulleter.id && commenter.notification_reflector && commenter.email.length > 0
      UserMailer.someone_reflected_your_point(commenter, self, comment)
      message_sent_to[commenter.id]
    end

    return message_sent_to
  end
end
