#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class Commentable::Comment < ActiveRecord::Base
  is_reflectable
  is_trackable
  is_followable
  is_moderatable :text_fields => [:body], :moderatable_objects => lambda {
    Commentable::Comment.where('id > -1') #tacked on this where in order to enable chaining
  }

  has_paper_trail :only => [:title, :body, :subject, :user_id]  
  
  #acts_as_nested_set :scope => [:commentable_id, :commentable_type]
  validates_presence_of :body
  validates_presence_of :user
    
  belongs_to :user
  belongs_to :commentable, :polymorphic=>true, :touch => true

  acts_as_tenant(:account)

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

  def text(max_len = 140)
    body.length > max_len ? "#{body[(0..max_len)]}..." : body
  end

end
