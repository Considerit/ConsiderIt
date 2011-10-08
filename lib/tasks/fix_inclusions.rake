
require 'pp'
namespace :admin do
  task :fix_inc => :environment do
    f = File.open('lib/tasks/production.log', 'rb')
    s = f.read

    positions = {}
    reg = /Started POST "\/options\/(?<option_id>[\d]+)\/positions" for (?<ip>[\d|\.]+) at (?<time>[\d|\-]+ [\d|\:]+) -0700[\s]+Processing by PositionsController#create as JS[\s]+Parameters: {"utf8"=>"", "authenticity_token"=>"[^"]+", "position"=>{"stance"=>"[-|\d|\.]+", "option_id"=>"[\d]+", "position_id"=>"(?<position_id>[\d]+)"}, "commit"=>"", "option_id"=>"[\d]+"}/
    result = s.scan(reg)
    result.each do |option_id,ip,time,position_id|
      if !positions.has_key? ip
        positions[ip] = {}
      end
      positions[ip][option_id] = position_id
    end

    reg = /Started POST "\/options\/(?<option_id>[\d]+)\/positions\/(?<position_id>[\d]+)" for (?<ip>[\d|\.]+) at (?<time>[\d|\-]+ [\d|\:]+)/
    result = s.scan(reg)
    result.each do |option_id,position_id,ip,time|
      if !positions.has_key? ip
        positions[ip] = {}
      end
      positions[ip][option_id] = position_id
    end

    reg = /Started POST "\/options\/(?<option_id>[\d]+)\/points\/(?<point_id>[\d]+)\/inclusions\?page=[\d]+" for (?<ip>[\d|\.]+) at (?<time>[\d|\-]+ [\d|\:]+)/
    result = s.scan(reg)
    position_matches = []
    ip_matches = []
    result.each do |option_id,point_id,ip,time|
      if positions.has_key? ip
        ip_matches.push ip
        if positions[ip].has_key? option_id
          position_matches.push([option_id, positions[ip][option_id], point_id])

        end
      else
        p "CANT FIND #{ip}"
      end
    end

    reg = /Started POST "\/options\/(?<option_id>[\d]+)\/points\/(?<point_id>[\d]+)\/inclusions\?delete=true\&page=[\d]+" for (?<ip>[\d|\.]+) at (?<time>[\d|\-]+ [\d|\:]+)/
    result = s.scan(reg)
    result.each do |option_id,point_id,ip,time|
      if positions.has_key? ip
        if positions[ip].has_key? option_id
          if position_matches.include? [option_id, positions[ip][option_id], point_id]
            position_matches.delete [option_id, option_id, point_id]
            pp 'deleting inclusion!'
          end
        end
      end
    end

    position_matches.each do |option_id, position_id, point_id|
      position = Position.find(position_id)
      pp position.user_id
      pp position.user.id
      user_id = position.user_id
      existing = Inclusion.where(:user_id => user_id, :option_id => option_id, :point_id => point_id)
      if existing.count == 0
        p "Inclusion.create!( :user_id => #{user_id}, :position_id => #{position_id}, :point_id => #{point_id}, :option_id => #{option_id} )"
      end
    end

  end
end