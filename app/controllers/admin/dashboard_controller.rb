require 'date'

class Admin::DashboardController < ApplicationController
  
  def index
    @series = []

    names = ['~Visitors', 'Users', 'Positions', 'Inclusions','Points', 'Comments', 'Misc client activities']
    [Session, User, Position, Inclusion, Point, Comment, StudyData].each_with_index do |data, idx|
      dates = {}
      data.all.each do |row|
        if !row.created_at.nil?
          date = row.created_at.in_time_zone("Pacific Time (US & Canada)").to_date
          dates[date] ||= 0
          dates[date] += 1  
        end         
      end

      time = []
      dates.each do |date, cnt|
        time.push([ "Date.UTC(#{date.year}, #{date.month}, #{date.day}, 0, 0, 0)" , cnt, date])
      end

      time.sort! {|x,y| x[2] <=> y[2] }

      cumulative = []
      prev = 0
      time.each_with_index do |row, idx|
        cumulative.push([row[0], row[1] + prev])
        prev += row[1]
      end

      yAxisOptions = [
        {
          alternateGridColor: nil,
          gridLineWidth: true,
          opposite: false,
          minorGridLineWidth: 0,
          min: 0,
          title: {
            text: "'#{names[idx]}'"
          },
          lineWidth: 2
        },{
          alternateGridColor: nil,
          gridLineWidth: false,
          opposite: true,
          minorGridLineWidth: 0,
          min: 0,
          title: {
            text: "'cumulative #{names[idx]}'"
          },
          lineWidth: 2
        }].to_json.gsub('"', '');

      seriesOptions = [
        {
          name: "'#{names[idx]}'",
          data: time,
          yAxis: 0
        },
        {
          name: "'cumulative #{names[idx]}'",
          data: cumulative,
          yAxis: 1
        }
      ].to_json.gsub('"', '')

      chartOptions = {
        alignTicks: false,
        backgroundColor: "'#FFFFFF'",
        borderColor: "'#4572A7'",
        borderRadius: 5,
        borderWidth: 0,
        height: 500,
        marginTop: nil,
        marginRight: 130,
        marginBottom: 70,
        marginLeft: 20,
        panning: true,
        plotBackgroundColor: nil,
        plotBackgroundImage: nil,
        plotBorderColor: "'#C0C0C0'",
        plotBorderWidth: 0,
        plotShadow: false,
        reflow: true,
        renderTo: "'container-#{names[idx]}'",
        selectionMarkerFill: "'rgba(69,114,167,0.25)'",
        shadow: false,
        spacingTop: 50,
        spacingRight: 10,
        spacingBottom: 15,
        spacingLeft: 10,
        type: "'line'",
        width: nil,
        zoomType: "''"
      }.to_json.gsub('"', '')

      title = {
        text: "'#{names[idx]}'",
        style: {
          fontSize: "'40px'"
        }
      }.to_json.gsub('"', '')

      @series.push([seriesOptions, yAxisOptions, names[idx], chartOptions, title])

    end

  end

end