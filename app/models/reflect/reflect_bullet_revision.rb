class Reflect::ReflectBulletRevision < ActiveRecord::Base
  belongs_to :comment
  belongs_to :user
  is_trackable
  belongs_to :bullet, :class_name => 'Reflect::ReflectBullet', :foreign_key => 'bullet_id' 
  has_many :highlights, :class_name => 'Reflect::ReflectHighlight', :foreign_key => 'bullet_rev', :dependent => :destroy
  has_many :responses, :class_name => 'Reflect::ReflectResponseRevision', :foreign_key => 'bullet_rev', :dependent => :destroy

  acts_as_tenant(:account)

  default_scope where( :active => true )

  def notify_parties(current_tenant, options)
    commenter = comment.user
    message_sent_to = {}
    bulleter = user
    position = get_position_for_user(comment, commenter)

    if commenter.id != bulleter.id && position && position.notification_author && commenter.email.length > 0
      UserMailer.delay.someone_reflected_your_point(commenter, self, comment, options)
      message_sent_to[commenter.id]
    end

    return message_sent_to
  end

  private
    def get_position_for_user(comment, user)
      obj = comment.root_object
      commentable_type = comment.commentable_type

      begin
        if commentable_type == 'Point' 
          user.positions.published.find_by_proposal_id(obj.proposal_id)
        elsif commentable_type == 'Position'
          if user.id == obj.user_id
            obj
          else
            user.positions.published.find_by_proposal_id(obj.proposal_id)
          end
        end
      rescue
        nil
      end
    end  

end
