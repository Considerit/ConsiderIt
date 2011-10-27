class Admin::DashboardController < ApplicationController
  
  def index
    @series = []

    names = ['Users', 'Points', 'Inclusions', 'Comments']
    [User, Point, Inclusion, Comment].each_with_index do |data, idx|
      dates = {}
      data.all.each do |row|
        split_date = row.created_at.to_s.split(/[- :]/)
        date_key = [split_date[0], split_date[1].to_i-1, split_date[2]]
        dates[date_key] ||= 0
        dates[date_key] += 1           
      end

      time = []
      dates.each do |split_date, val|
        time.push([ "Date.UTC(#{split_date[0]}, #{split_date[1].to_i-1}, #{split_date[2]}, 0, 0, 0)" , val])
      end

      time.sort! {|x,y| x[0] <=> y[0] }
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
    @series = @series

  end

end