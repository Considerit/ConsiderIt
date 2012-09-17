#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

module Moderatable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class ModeratableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
    config.before_configuration do |app|
      app.config.assets.paths << Rails.root.join("lib", "gems", "moderatable", "app", "assets")
    end
  end

  module Moderatable
    def is_moderatable(options = {})
      has_many :moderations, :as => :moderatable, :class_name => 'Moderatable::Moderation', :dependent => :destroy
      
      class_attribute :text_fields
      self.text_fields = options[:text_fields]

      include InstanceMethods
    end
    module InstanceMethods
      def moderatable?
        true
      end

    end
  end

end

ActiveRecord::Base.extend Moderatable::Moderatable
require 'moderatable/routes'