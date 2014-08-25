module Followable
  extend ActiveSupport::Concern

  included do 
    has_many :follows, :as => :followable, :class_name => 'Follow', :dependent => :destroy
    accepts_nested_attributes_for :follows
  end

  def followable?
    true
  end

  def get_explicit_follow(user)
    Follow.where(:followable_type => self.class.name, :user_id => user.id).find_by_followable_id(self.id)
  end

  def follow!(user, params)
    if user.nil?
      return
    end
    follow = params[:follow]
    explicit = params[:explicit]

    existing = get_explicit_follow user

    if existing
      unless existing.explicit && !explicit
        existing.follow = follow
        existing.explicit = explicit
        existing.save
      end
      return existing
    else
      params = {
        :followable_type => self.class.name,
        :followable_id => self.id,
        :user_id => user.id,
        :follow => follow,
        :explicit => explicit
      }
      params[:account_id] = account_id if self.respond_to? :account        
      Follow.create! ActionController::Parameters.new(params).permit!
      return Follow.last
    end
  end

end