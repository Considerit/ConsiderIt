class ActivitiesController < ApplicationController
  def feed
    @actions = Activity.order('created_at DESC').limit(300)

    respond_to do |format|
      format.html
      format.rss { render :layout => false } #index.rss.builder
    end
  end
end