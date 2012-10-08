#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

module Assessable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class AssessableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
    config.before_configuration do |app|
      app.config.assets.paths << Rails.root.join("lib", "gems", "assessable", "app", "assets")
    end
  end

  module Assessable
    def is_assessable(options = {})
      has_one :assessment, :as => :assessable, :class_name => 'Assessable::Assessment', :dependent => :destroy
      
      class_attribute :text_fields
      self.text_fields = options[:text_fields]

      class_attribute :assessable_objects
      self.assessable_objects = options[:assessable_objects]
      
      include InstanceMethods
    end
    module InstanceMethods
      def assessable?
        true
      end

    end
  end

end

ActiveRecord::Base.extend Assessable::Assessable


require 'assessable/routes'