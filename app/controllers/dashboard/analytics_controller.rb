require 'date'

class Dashboard::AnalyticsController < ApplicationController
  
  def index

    @series = []
    start = nil #'2012-09-20 00:00:00'

    has_permission = current_user && (current_user.is_admin? || current_user.has_role?(:analyst) )
    classes = has_permission ? [Session, User, Position, Inclusion, Point, Commentable::Comment] : []
    classes.each_with_index do |data, idx|
      dates = {}
      name = data.name.split('::').last

      if start
        data = data.where("created_at > '#{start}'")
      end

      if [Position, Point].include?(data)
        qry = data.published
      elsif [Inclusion].include?(data)
        qry = data.joins(:position).where('positions.published = 1')
      else 
        qry = data.all
      end

      qry.each do |row|
        if !row.created_at.nil?
          date = row.created_at.in_time_zone("Pacific Time (US & Canada)").to_date
          dates[date] ||= 0
          dates[date] += 1  
        end         
      end

      time = []
      dates.sort_by{ |k,v| k}.each do |date, cnt|
        time.push([date.strftime('%s').to_i * 1000, cnt ])
      end

      time.sort! {|x,y| x[2] <=> y[2] }

      cumulative = []
      prev = 0
      time.each_with_index do |row, idx|
        cumulative.push([row[0], row[1] + prev])
        prev += row[1]
      end

      #@series.push([seriesOptions, yAxisOptions, data.name, chartOptions, title])
      @series.push( {
        :title => name,
        :main => { :title => name, :data => time}, 
        :cumulative => { :title => 'Cumulative ' + name, :data => cumulative}
      })
    end

    render :template => 'dashboard/analytics/index'

  end

end