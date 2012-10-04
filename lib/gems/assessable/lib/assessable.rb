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
      has_many :assessments, :as => :assessable, :class_name => 'Assessable::Assessment', :dependent => :destroy
      
      include InstanceMethods
    end
    module InstanceMethods
      def assessable?
        true
      end

    end
  end

end

ActiveRecord::Base.extend Assessable::Assessment
require 'assessable/routes'