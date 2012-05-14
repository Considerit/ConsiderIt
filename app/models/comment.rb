class Comment < ActiveRecord::Base
  is_reflectable
  has_paper_trail  
  
  #acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :commentable, :polymorphic=>true

  has_many :reflect_bullets, :class_name => 'Reflect::ReflectBullet', :dependent => :destroy
  has_many :reflect_bullet_revisions, :class_name => 'Reflect::ReflectBulletRevision', :dependent => :destroy

  # Helper class method that allows you to build a comment
  # by passing a commentable object, a user_id, and comment text
  # example in readme
  def self.build_from(obj, user_id, comment)
    c = self.new
    c.commentable_id = obj.id 
    c.commentable_type = obj.class.name 
    c.body = comment 
    c.user_id = user_id
    c
  end

  def violation
    false
  end

  def root_object
    commentable_type.constantize.find(commentable_id)
  end

  def notify_parties(current_tenant, options)
    message_sent_to = {}

    begin
      obj = root_object

      # notify creator of root object
      author = obj.user
      author_position = get_position_for_user_and_obj(author, obj, commentable_type)

      if author.id != user_id && author_position && author_position.notification_author && author.email.length > 0
        if author.email && author.email.length > 0
          if commentable_type == 'Point'
            UserMailer.delay.someone_discussed_your_point(author, obj, self, options)#.deliver
          elsif commentable_type == 'Position'
            UserMailer.delay.someone_discussed_your_position(author, obj, self, options)#.deliver
          end
        end
      end
      # if they don't want to get comments for their own stuff, then they also don't want  
      # notifications for other derivative notifications
      message_sent_to[author.id] = [author.name, 'point discussed']

      # For all other participants in the discussion...
      obj.comments.each do |comment|
        recipient = comment.user
        recipient_position = get_position_for_user_and_obj(recipient, obj, commentable_type)

        if !message_sent_to.has_key?(recipient.id) \
          && recipient_position \
          && recipient_position.notification_demonstrated_interest \
          && recipient.id != user_id 

          if recipient.email && recipient.email.length > 0   
            UserMailer.delay.someone_commented_on_thread(recipient, obj, self, options)#.deliver
          end
          message_sent_to[recipient.id] = [recipient.name, 'same discussion']
        end
      end

      if commentable_type == 'Point'
        point = obj
        point.inclusions.each do |inclusion|
          if inclusion.user.positions.published.find(inclusion.proposal_id).notification_demonstrated_interest
            includer = inclusion.user
            if !message_sent_to.has_key?(includer.id) && includer.id == user_id
              if includer.email && includer.email.length > 0
                UserMailer.delay.someone_commented_on_an_included_point(includer, point, self, options)#.deliver
              end
              message_sent_to[recipient.id] = [recipient.name, 'comment on included point']
            end
          end
        end
      end
    rescue
    end

    return message_sent_to
  end

  private
    def get_position_for_user_and_obj(user,obj,commentable_type)
      begin
        if commentable_type == 'Point' 
          user.positions.published.find(obj.position_id)
        elsif commentable_type == 'Position'
          if user.id == obj.user_id
            obj
          else
            user.positions.published.find(obj.id)
          end
        end
      rescue
        nil
      end
    end

end
