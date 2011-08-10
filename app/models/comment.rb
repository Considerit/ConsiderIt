class Comment < ActiveRecord::Base
  acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  has_one :point
  validates_presence_of :body
  validates_presence_of :user
  
  # NOTE: install the acts_as_votable plugin if you 
  # want user to vote on the quality of comments.
  #acts_as_voteable
  
  # NOTE: Comments belong to a user
  belongs_to :user
  
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

  # TODO: implement below
  # def notify_parties(send = APP_CONFIG['send_email'])
  #   message_sent_to = {}
  #   initiative = find_commentable
  #   grounded_in_point = !point.nil?
    
  #   if !parent_id.nil?
  #     parent_commenter = Comment.find(parent_id).user

  #     if parent_commenter.id != user_id && parent_commenter.user_mailer_preferences.comment_response
  #       if send
  #         Notifier.deliver_someone_replied_to_your_comment(initiative, self, parent_commenter)
  #       end
  #       message_sent_to[parent_commenter.id] = [parent_commenter.name, 'replied to']
  #     end
  #   end
    
  #   if grounded_in_point && !message_sent_to.key?(point.user_id)
  #     point_author = point.user
  #     if point_author.id != user_id && point_author.user_mailer_preferences.point_discussed
  #       if send
  #         Notifier.deliver_someone_discussed_your_point(initiative, point, self, point_author)
  #       end
  #       message_sent_to[point_author.id] = [point_author.name, 'point discussed']
  #     end
  #   end

  #   if parent_id
  #     parent = Comment.find(parent_id)
  #     if !parent.parent_id.nil?
  #       parent = parent.root
  #     end
      
  #     parent.root.self_and_descendants.each do |comment|
  #       if comment.created_at < created_at
  #         recipient = comment.user
  #         if !message_sent_to.key?(recipient.id) \
  #           && recipient.user_mailer_preferences.thread_commented \
  #           && recipient.id != user_id 
  #           if send
  #             Notifier.deliver_someone_commented_on_thread(initiative, self, recipient)
  #           end
  #           message_sent_to[recipient.id] = [recipient.name, 'same discussion']
  #         end
  #       end
  #     end
  #   end
  #   return message_sent_to
  # end

end
