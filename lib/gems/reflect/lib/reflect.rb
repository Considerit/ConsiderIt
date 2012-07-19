#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

require "reflect/version"

module Reflect
  class Engine < ::Rails::Engine #:nodoc:
  end

  class ReflectRailtie < ::Rails::Railtie
    initializer 'reflect' do |app|
      #ActiveSupport.on_load(:active_record) do
      #  ::ActiveRecord::Base.send :include, Reflect::Reflectable
      #end

      #app.paths.views.push Reflect.view_path      
    end

    config.before_configuration do |app|
      app.config.assets.paths << Rails.root.join("lib", "gems", "reflect", "app", "assets")
    end

  end

end

module Reflect
  module Reflectable
    def is_reflectable
      #has_many :reflect_bullets, :as=>:reflectable, :dependent=>:destroy
      has_many :reflect_bullets, :as=>:reflectable, :class_name => 'Reflect::ReflectBullet', :dependent => :destroy
      has_many :reflect_bullet_revisions, :class_name => 'Reflect::ReflectBulletRevision', :dependent => :destroy

      include InstanceMethods
    end
    module InstanceMethods
      def reflectable?
        true
      end
    end
  end
end
ActiveRecord::Base.extend Reflect::Reflectable