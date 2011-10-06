class Comment < ActiveRecord::Base
  acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :point
  belongs_to :option

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

  #helper method to check if a comment has children
  def has_children?
    self.children.size > 0 
  end
  
  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  scope :find_comments_by_user, lambda { |user|
    where(:user_id => user.id).order('created_at DESC')
  }

  # Helper class method to look up all comments for 
  # commentable class name and commentable id.
  scope :find_comments_for_commentable, lambda { |commentable_str, commentable_id|
    where(:commentable_type => commentable_str.to_s, :commentable_id => commentable_id).order('created_at DESC')
  }

  # Helper class method to look up a commentable object
  # given the commentable class name and id 
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def notify_parties
    message_sent_to = {}

    begin
    
      point_author = point.user
      if point_author.id != user_id && point_author.notification_author && point_author.email.length > 0
        #Notifier.deliver_someone_discussed_your_point(option, point, self, point_author)
        message_sent_to[point_author.id] = [point_author.name, 'point discussed']
      end

      point.comments.each do |comment|
        recipient = comment.user
        if !message_sent_to.has_key?(recipient.id) \
          && recipient.notification_commenter \
          && recipient.id != user_id 

          #Notifier.deliver_someone_commented_on_thread(option, self, recipient)
          message_sent_to[recipient.id] = [recipient.name, 'same discussion']
        end
      end

      point.inclusions.each do |inclusion|
        if inclusion.user.positions.find(option.id).notification_includer
          includer = inclusion.user
          if !message_sent_to.has_key?(includer.id) && includer.id == user_id
            #Notifier.deliver_someone_commented_on_an_included_point(option, self, includer)
            message_sent_to[recipient.id] = [recipient.name, 'comment on included point']
          end
        end
      end
    rescue

    end

    return message_sent_to
  end

end
