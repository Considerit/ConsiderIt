#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

class ActivitiesController < ApplicationController
  def feed
    @actions = Activity.order('created_at DESC').limit(300)

    respond_to do |format|
      format.html
      format.rss { render :layout => false } #index.rss.builder
    end
  end
end