module Thankable
  class Engine < ::Rails::Engine #:nodoc:
  end

  class ThankableRailtie < ::Rails::Railtie
    #initializer 'init' do |app|
    #end
    # config.before_configuration do |app|
    #   app.config.assets.paths << Rails.root.join("lib", "gems", "thankable", "app", "assets")
    # end
  end

  module Thankable
    def is_thankable(options = {})
      has_many :thanks, :as => :thankable, :class_name => 'Thank', :dependent => :destroy
      
      include InstanceMethods
    end
    module InstanceMethods
      def thankable?
        true
      end

    end
  end

end

ActiveRecord::Base.extend Thankable::Thankable
require 'thankable/routes'