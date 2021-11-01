task :migrate_inclusions_to_opinions => :environment do 
  Inclusion.all.each do |i|
    point = i.point

    if point && point.published 

      if i.user && i.user.registered
        begin
          opinion = i.user.opinions.find_by_proposal_id(point.proposal_id)
        rescue 
          pp "Could not find an associated opinion for Inclusion #{i.id}"
          next
        end 

        next if !opinion || !opinion.published || Opinion.where(:statement_type => "Point", :statement_id => point.id, :user_id => i.user_id).count > 0

        o = {
          subdomain_id: point.subdomain_id,
          created_at: i.created_at,
          updated_at: i.updated_at,
          statement_id: point.id,
          statement_type: 'Point',
          stance: 0.5,
          user_id: i.user_id,
          published: true,
        }

        oo = Opinion.new o
        oo.save

      end
    end
  end

end