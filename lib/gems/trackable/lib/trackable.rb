#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

module Trackable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class TrackableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
  end

  module Trackable
    def is_trackable
      has_many :activities, :as=>:action, :dependent=>:destroy
      include InstanceMethods
    end

    module InstanceMethods
      def track!
        Activity.build_from!(self)
      end

      def tracked?
        true
      end

    end
  end

end

ActiveRecord::Base.extend Trackable::Trackable
