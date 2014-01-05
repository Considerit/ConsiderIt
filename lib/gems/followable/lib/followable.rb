module Followable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class FollowableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
    config.before_configuration do |app|
      app.config.assets.paths << Rails.root.join("lib", "gems", "followable", "app", "assets")
    end
  end

  module Followable
    def is_followable
      has_many :follows, :as => :followable, :class_name => 'Followable::Follow', :dependent => :destroy
      accepts_nested_attributes_for :follows


    
      include InstanceMethods
    end
    module InstanceMethods
      def followable?
        true
      end

      def follow!(user, params)
        if user.nil?
          return
        end
        follow = params[:follow]
        explicit = params[:explicit]

        existing = Follow.where(:followable_type => self.class.name, :user_id => user.id).find_by_followable_id(self.id)

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
  end

end

ActiveRecord::Base.extend Followable::Followable
require 'followable/routes'