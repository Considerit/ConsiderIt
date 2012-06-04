module ActsAsFollowable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class ActsAsFollowableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
    config.before_configuration do |app|
      app.config.assets.paths << Rails.root.join("lib", "gems", "acts_as_followable", "app", "assets")
    end
  end

  module Followable
    def acts_as_followable
      has_many :follows, :as => :followable, :class_name => 'ActsAsFollowable::Follow', :dependent => :destroy
      accepts_nested_attributes_for :follows

      include InstanceMethods
    end
    module InstanceMethods
      def followable?
        true
      end

      def follow!(user, params)
        follow = params[:follow]
        explicit = params[:explicit]

        existing = ActsAsFollowable::Follow.where(:followable_type => self.class.name, :user_id => user.id).find_by_followable_id(self.id)

        if existing
          unless existing.explicit && !explicit
            existing.follow = follow
            existing.explicit = explicit
            existing.save
          end
        else
          params = {
            :followable_type => self.class.name,
            :followable_id => self.id,
            :user_id => user.id,
            :follow => follow,
            :explicit => explicit
          }
          params[:account_id] = account_id if self.respond_to? :account        
          ActsAsFollowable::Follow.create!(params)
        end
      end
    end
  end


  module ControllerMethods
    def follow
      followable_type = params[:follow][:followable_type]
      followable_id = params[:follow][:followable_id]
      obj_to_follow = followable_type.constantize.find(followable_id)
      obj_to_follow.follow!(current_user, :follow => true, :explicit => true)
      render :json => {:success => true}.to_json
    end

    def unfollow
      if params.has_key? :t
        followable_id = params[:i]
        followable_type = params[:m]
        obj_to_follow = followable_type.constantize.find(followable_id)
        if params[:t] == ApplicationController.token_for_action(params[:u], obj_to_follow, 'unfollow')
          obj_to_follow.follow!(current_user, :follow => false, :explicit => true)
        end
        #TODO: get the model's path to redirect to
        redirect_to root_path    
      else
        followable_type = params[:follow][:followable_type]
        followable_id = params[:follow][:followable_id]
        obj_to_follow = followable_type.constantize.find(followable_id)
        obj_to_follow.follow!(current_user, :follow => false, :explicit => true)
        render :json => {:success => true}.to_json
      end
    end 

  end
end

ActiveRecord::Base.extend ActsAsFollowable::Followable
