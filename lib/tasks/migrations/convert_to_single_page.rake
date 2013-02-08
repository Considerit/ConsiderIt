# encoding: UTF-8

require 'pp'

namespace :single_page do
  desc ""  
  task :inclusions_on_position => :environment do  

    ActiveRecord::Base.connection.execute( "UPDATE positions SET point_inclusions=(SELECT COUNT(*) FROM users u, inclusions i WHERE u.id=positions.user_id AND u.id=i.user_id AND positions.proposal_id=i.proposal_id) WHERE published=1"  ) 

    Position.transaction do

      Position.published.each do |position|      
       position.point_inclusions = Inclusion.where(:user_id => position.user_id).where(:proposal_id => position.proposal_id).select(:point_id).map {|x| x.point_id}.compact.to_s


       #position.inclusions(:select => [:point_id]).map {|x| x.point_id}.compact.to_s      
       position.save
      end
    end
  end
end


