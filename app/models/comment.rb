class Comment < ActiveRecord::Base
  is_reflectable
  
  #acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :commentable, :polymorphic=>true


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

  def notify_parties
    message_sent_to = {}

    begin
      obj = root_object()

      author = obj.user
      if author.id != user_id && author.notification_author && author.email.length > 0
        if author.email && author.email.length > 0
          UserMailer.someone_discussed_your_point(author, obj, self).deliver
        end
      end
      # if they don't want to get comments for their own points, don't notifications for other 
      # derivative notifications
      message_sent_to[author.id] = [author.name, 'point discussed']

      if commentable_type == 'Point'
        point = obj
        point.comments.each do |comment|
          recipient = comment.user
          if !message_sent_to.has_key?(recipient.id) \
            && recipient.notification_commenter \
            && recipient.id != user_id 

            if recipient.email && recipient.email.length > 0
              UserMailer.someone_commented_on_thread(recipient, point, self).deliver
            end
            message_sent_to[recipient.id] = [recipient.name, 'same discussion']
          end
        end

        point.inclusions.each do |inclusion|
          if inclusion.user.positions.find(option.id).notification_includer
            includer = inclusion.user
            if !message_sent_to.has_key?(includer.id) && includer.id == user_id
              if includer.email && includer.email.length > 0
                UserMailer.someone_commented_on_an_included_point(includer, point, self).deliver
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

end
