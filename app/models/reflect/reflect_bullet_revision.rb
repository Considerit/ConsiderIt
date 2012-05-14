class Reflect::ReflectBulletRevision < ActiveRecord::Base
  belongs_to :comment
  belongs_to :user

  belongs_to :bullet, :class_name => 'ReflectBullet', :foreign_key => 'bullet_id' 
  has_many :highlights, :class_name => 'ReflectHighlight', :foreign_key => 'bullet_rev', :dependent => :destroy
  has_many :responses, :class_name => 'ReflectResponseRevision', :foreign_key => 'bullet_rev', :dependent => :destroy
  
  default_scope where( :active => true )

  def notify_parties(current_tenant, options)
    commenter = comment.user
    message_sent_to = {}
    bulleter = user
    position = get_position_for_user(comment, commenter)

    if commenter.id != bulleter.id && position.notification_author && commenter.email.length > 0
      UserMailer.delay.someone_reflected_your_point(commenter, self, comment, options)
      message_sent_to[commenter.id]
    end

    return message_sent_to
  end

  private
    def get_position_for_user(comment, user)
      obj = comment.root_object
      commentable_type = comment.commentable_type

      if commentable_type == 'Point' 
        user.positions.published.find(obj.position_id)
      elsif commentable_type == 'Position'
        if user.id == obj.user_id
          obj
        else
          user.positions.published.find(obj.id)
        end
      end
    end  

end
