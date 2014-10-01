require 'uri'

namespace :metrics do
  desc "Create metrics output"

  task :deeper => :environment do
    puts "Number\tName\topinions\tpoints\tinclusions\tInclusions per point\tInclusions per opinion"
    Proposal.where(:domain_short => 'WA State').each do |p|
      printf("%i\t%s\t%i\t%i\t%i\t%.2f\t%.2f\n",
        p.designator,p.short_name,p.opinions.published.count,p.points.published.count,p.inclusions.count,
        p.inclusions.count.to_f / p.points.published.count,
        p.inclusions.count.to_f / p.opinions.published.count)
    end
  end

  task :basic => :environment do

    WASHINGTON = true
    if WASHINGTON
      years = [2010,2011,2012,2013]
      accnt_id = 1
    else
      years = [2012]
      accnt_id = 2
    end

    puts "Overall activities"
    puts "Year\tusers\topinions\tinclusions\tpoints\tcomments"
    years.each do |year|
      opinions = Opinion.published.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')
      users = User.where(:account_id => accnt_id).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')
      points = Point.published.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')      
      inclusions = Inclusion.where(:account_id => accnt_id).where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins('INNER JOIN opinions ON inclusions.user_id=opinions.user_id AND inclusions.proposal_id=opinions.proposal_id').where('opinions.published = 1')
      comments = Comment.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')

      printf("%i\t%s\t%i\t%i\t%i\t%i\n",
          year, users.count, opinions.count, inclusions.count, points.count, comments.count)

    end

    puts "Distinct users engaging in each activity"
    puts "Year\tusers\topinions\tinclusions\tpoints\tcomments"
    years.each do |year|
      opinions = Opinion.published.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').group(:user_id)
      users = User.where(:account_id => accnt_id).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')
      points = Point.published.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').group(:user_id)
      inclusions = Inclusion.where(:account_id => accnt_id).where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins('INNER JOIN opinions ON inclusions.user_id=opinions.user_id AND inclusions.proposal_id=opinions.proposal_id').where('opinions.published = 1').group("inclusions.user_id")
      comments = Comment.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').group(:user_id)

      printf("%i\t%s\t%i\t%i\t%i\t%i\n",
          year, 
          users.count, 
          opinions.count.keys.length, 
          inclusions.count.keys.length, 
          points.count.keys.length, 
          comments.count.keys.length)

    end

    puts "Advanced metrics"
    puts "Year\tInclusions per point\tinclusions per opinion\tcomments per point\topinions per user"
    years.each do |year|
      opinions = Opinion.published.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')
      users = User.where(:account_id => accnt_id).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')
      points = Point.published.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')      
      inclusions = Inclusion.where(:account_id => accnt_id).where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins('INNER JOIN opinions ON inclusions.user_id=opinions.user_id AND inclusions.proposal_id=opinions.proposal_id').where('opinions.published = 1')
      comments = Comment.where(:account_id => accnt_id).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')

      printf("%i\t%.2f\t%.2f\t%.2f\t%.2f\n",
          year, 
          inclusions.count.to_f / points.count, #inclusions per point
          inclusions.count.to_f / opinions.count, #inclusions per opinion
          comments.count.to_f / points.count, #comments per point
          opinions.count.to_f / users.count #opinions per user
      )
    end
  end

  task :fill_opinion_holes => :environment do 
    Point.published.where(:opinion_id => nil).each do |pnt|
      pnt.opinion = Opinion.where(:user_id => pnt.user_id).where(:proposal_id => pnt.proposal_id).last
      pnt.save
    end
    Inclusion.where(:opinion_id => nil).each do |inc|
      inc.opinion = Opinion.published.where(:user_id => inc.user_id).where(:proposal_id => inc.proposal_id).last
      inc.save
    end
  end

  task :normative_inclusion_overall => :environment do
    WASHINGTON = true
    if WASHINGTON
      years = [2010,2011,2012,2013]
      accnt_id = 1
    else
      years = [2012]
      accnt_id = 2
    end

    puts "Normative metrics"
    puts "Year\tIncluded pro & con\tIncluded point by opposer\tIncluded for your side\tIncluded for other side\tConviction"
    years.each do |year|
      opinions = Opinion.published.where(:account_id => accnt_id).where("YEAR(opinions.created_at)=#{year}").where('MONTH(opinions.created_at)>8').joins(:user).where('users.roles_mask=0')

      pro_and_con = 0
      not_pro_and_con = 0
      neither = 0
      inc_yr_side = 0
      inc_other_side = 0

      inc_enemy = {}

      THRESH = 1
      conviction = 0

      opinions.each do |pos|
        if pos.inclusions.count >= THRESH
          inc_points = pos.inclusions.joins(:point)
          conviction += pos.stance.abs
          if inc_points.where('points.is_pro=1').count > 0 && inc_points.where('points.is_pro=0').count > 0
            pro_and_con += 1
          else  
            not_pro_and_con += 1
          end

          if pos.stance > 0
            inc_yr_side += inc_points.where('points.is_pro=1').count
            inc_other_side += inc_points.where('points.is_pro=0').count
            inc_points.each do |inc|
              otheropinion = inc.point.user.opinions.published.where("proposal_id=#{pos.proposal_id}").count > 0 ? inc.point.user.opinions.published.find_by_proposal_id(pos.proposal_id) : nil
              if otheropinion && otheropinion.stance < 0 
                inc_enemy[pos.id] = 1
                break
              end
            end

          elsif pos.stance < 0
            inc_yr_side += inc_points.where('points.is_pro=0').count
            inc_other_side += inc_points.where('points.is_pro=1').count

            inc_points.each do |inc|
              otheropinion = inc.point.user.opinions.published.where("proposal_id=#{pos.proposal_id}").count > 0 ? inc.point.user.opinions.published.find_by_proposal_id(pos.proposal_id) : nil
              if otheropinion && otheropinion.stance > 0 
                inc_enemy[pos.id] = 1
                break
              end
            end

          else
            neither += 1 
          end
        end
      end

      printf("%i\t%.2f\t%.2f\t%i\t%i\t%.2f\n",
          year, 
          pro_and_con+not_pro_and_con > 0 ? pro_and_con.to_f / (pro_and_con+not_pro_and_con) : -1.0, #inclusions per point
          pro_and_con+not_pro_and_con-neither > 0 ? inc_enemy.keys().length.to_f / (pro_and_con+not_pro_and_con-neither) : -1.0, #inclusions per opinion
          inc_yr_side, 
          inc_other_side, 
          pro_and_con+not_pro_and_con > 0 ? conviction / (pro_and_con+not_pro_and_con) : -1.0
      )
    end

  end

  task :normative_inclusion_by_proposal => :environment do
    years = [2010,2011,2012,2013]
    puts "Normative metrics"
    puts "Year\tProposal\tIncluded pro & con\tIncluded point by opposer\tIncluded for your side\tIncluded for other side\tConviction"
    
    puts "Year\tProposal\tIncluded pro & con\tConviction"

    years.each do |year|

      Proposal.where(:account_id => 1).tagged_with(["#{year}", 'state'], :all => true).each do |prop|

        opinions = prop.opinions.published.joins(:user).where('users.roles_mask=0')
                
        pro_and_con = 0
        not_pro_and_con = 0
        neither = 0
        inc_yr_side = 0
        inc_other_side = 0

        THRESH = 1

        #if opinions.count < 100
        #  next
        #end

        contentiousness = 0.0

        opinions.each do |pos|
          if pos.inclusions.count >= THRESH
            contentiousness += pos.stance.abs

            inc_points = pos.inclusions.joins(:point)
            if inc_points.where('points.is_pro=1').count > 0 && inc_points.where('points.is_pro=0').count > 0
              pro_and_con += 1
            else  
              not_pro_and_con += 1
            end

            if pos.stance > 0
              inc_yr_side += inc_points.where('points.is_pro=1').count
              inc_other_side += inc_points.where('points.is_pro=0').count
            elsif pos.stance < 0
              inc_yr_side += inc_points.where('points.is_pro=0').count
              inc_other_side += inc_points.where('points.is_pro=1').count
            end
          else
            neither += 1 
          end
        end

        # printf("%i\t%i\t%.2f\t%.2f\t%i\t%i\t%.2f\n",
        #     year, 
        #     prop.designator,
        #     pro_and_con.to_f / (pro_and_con+not_pro_and_con), #inclusions per point
        #     pro_and_con.to_f / (pro_and_con+not_pro_and_con), #inclusions per opinion
        #     inc_yr_side, #inclusions per point
        #     inc_other_side, #inclusions per opinion  
        #     contentiousness / (pro_and_con+not_pro_and_con)        
        # )

        printf("%i\t%i\t%s\t%.2f\t%.2f\n",
            year, 
            prop.designator,
            prop.short_name,
            pro_and_con.to_f / (pro_and_con+not_pro_and_con), #inclusions per point
            contentiousness / (pro_and_con+not_pro_and_con)        
        )        
      end
    end

  end

  task :fact_checking_basic => :environment do 
    puts "Fact-checking metrics"

    requests = Assessable::Request.all

    results = {
      'unknown' => {:pro => 0, :con => 0 },
      'supporter' => {:pro => 0, :con => 0 },
      'opposer' => {:pro => 0, :con => 0 },
      'neutral' => {:pro => 0, :con => 0 }

    }

    requests.each do |rq|
      requester = rq.user
      
      begin
        pos = requester.opinions.published.where(:proposal_id => rq.root_object.proposal_id).last
      rescue
        next
      end

      is_pro = rq.root_object.is_pro ? :pro : :con

      if !pos
        stance = 'unknown'
      elsif pos.stance_segment > 3
        stance = 'supporter'
      elsif pos.stance_segment == 3
        stance = 'neutral'
      else
        stance = 'opposer'
      end

      results[stance][is_pro] += 1

    end
    pp results

  end

  task :fact_checking_rates => :environment do 
    puts "Computing average commenting rate and inclusion rate"

    Assessable::Assessment.find_each do |ass|
      #pp "Created at: #{ass.created_at}, Updated at: #{ass.updated_at}"
      #pp "requested at: #{ass.requests.first.created_at}"
    end
    average_date = Assessable::Assessment.select('FROM_UNIXTIME(AVG(UNIX_TIMESTAMP(created_at) + (UNIX_TIMESTAMP(updated_at) - UNIX_TIMESTAMP(created_at))/2 )) as updated_at')
    average_date = average_date[0].updated_at

    points = Assessable::Assessment.select('distinct(assessable_id)').map {|a| a.assessable_id }.compact

    proposals = points.map {|p| Point.find(p).proposal_id}.compact.uniq

    nonfactchecked=false
    if nonfactchecked
      inclusions_all = Inclusion.where("proposal_id in (?) and point_id not in (?)", proposals, points)

      all_points = Point.where("proposal_id in (?)", proposals)
      comments_all = Comment.where("point_id in (?) and point_id not in (?)", all_points.map {|p| p.id}.compact, points)

      all_views = PointListing.where("point_id in (?) and point_id not in (?)", all_points.map {|p| p.id}.compact, points)

      views_before = all_views.where('created_at < "' + average_date.to_s + '"').count
      views_after = all_views.where('created_at >= "' + average_date.to_s + '"').count

      comments_before = comments_all.where('created_at < "' + average_date.to_s + '"').count
      comments_after = comments_all.where('created_at >= "' + average_date.to_s + '"').count

      inclusions_before = inclusions_all.where('created_at < "' + average_date.to_s + '"').count
      inclusions_after = inclusions_all.where('created_at >= "' + average_date.to_s + '"').count
    else
      inclusions_all = Inclusion.where("point_id in (?)", points)

      comments_all = Comment.where("point_id in (?)", points)

      all_views = PointListing.where("point_id in (?)", points)

      views_before = all_views.where('created_at < "' + average_date.to_s + '"').count
      views_after = all_views.where('created_at >= "' + average_date.to_s + '"').count

      comments_before = comments_all.where('created_at < "' + average_date.to_s + '"').count
      comments_after = comments_all.where('created_at >= "' + average_date.to_s + '"').count

      inclusions_before = inclusions_all.where('created_at < "' + average_date.to_s + '"').count
      inclusions_after = inclusions_all.where('created_at >= "' + average_date.to_s + '"').count
    end


    pp "BEFORE"
    pp "Views: #{views_before}"
    pp "Comments: #{comments_before}"
    pp "Rate: #{comments_before.to_f/views_before}"

    pp "Inclusions: #{inclusions_before}"
    pp "Rate: #{inclusions_before.to_f/views_before}"

    pp "AFTER"
    pp "Views: #{views_after}"
    pp "Comments: #{comments_after}"
    pp "Rate: #{comments_after.to_f/views_after}"

    pp "Inclusions: #{inclusions_after}"
    pp "Rate: #{inclusions_after.to_f/views_after}"

  end

  task :fact_checking => :environment do 
    puts "Fact-checking metrics"


    impacts = []
    [0,1,2].each do |verdict|
      puts "For points with an overall " + verdict.to_s + " verdict"
      col = :overall_verdict
      #col = :max_verdict
      assessments = Assessable::Assessment.where(col => verdict)

      inclusions = { :before => 0, :after => 0 } 
      views = { :before => 0, :after => 0 }

      normalized_impact = 0
      cnt = 0

      assessments.each do |ass|
        pivot = ass.updated_at
        point = ass.root_object

        #next if ass.claims.count > 1
        #next if point.point_listings.where('created_at > "' + pivot.to_s + '"').count < 10


        population_before = point.proposal.inclusions.where('created_at < "' + pivot.to_s + '"').count.to_f / point.proposal.point_listings.where('created_at < "' + pivot.to_s + '"').count
        population_after = point.proposal.inclusions.where('created_at > "' + pivot.to_s + '"').count.to_f / point.proposal.point_listings.where('created_at > "' + pivot.to_s + '"').count
        population_after = population_after.infinite? ? 1.0 : population_after

        point_before = point.inclusions.where('created_at < "' + pivot.to_s + '"').count.to_f / point.point_listings.where('created_at < "' + pivot.to_s + '"').count
        point_after = point.inclusions.where('created_at > "' + pivot.to_s + '"').count.to_f / point.point_listings.where('created_at > "' + pivot.to_s + '"').count
        point_after = point_after.infinite? ? 1.0 : point_after

        next if point_after.nan?

        normalized_impact += (point_before > 0 ? point_after / point_before : 0) - (population_before > 0 ? population_after / population_before : 0)
        inclusions[:before] += point.inclusions.where('created_at < "' + pivot.to_s + '"').count
        inclusions[:after] += point.inclusions.where('created_at > "' + pivot.to_s + '"') .count
        views[:before] += point.point_listings.where('created_at < "' + pivot.to_s + '"').count
        views[:after] += point.point_listings.where('created_at > "' + pivot.to_s + '"').count
        cnt += 1

        impacts.push([point, normalized_impact, cnt, point.point_listings.where('created_at > "' + pivot.to_s + '"').count, verdict])

      end

      printf("%s:\tinclusions %i\tviews %i\t%.3f\n", 'Before', inclusions[:before], views[:before], inclusions[:before].to_f / views[:before] )
      printf("%s:\tinclusions %i\tviews %i\t%.3f\n", 'After', inclusions[:after], views[:after], inclusions[:after].to_f / views[:after] )

      printf("Impact:\t%.3f\n", (inclusions[:after].to_f / views[:after]) / (inclusions[:before].to_f / views[:before]) )
      printf("Normalized:\t%.3f\n", normalized_impact / cnt )
      pp cnt


    end

    impacts.sort! {|a,b| a[1] <=> b[1]}

    impacts.each do |i|
      printf("%i\t%i\t%i\t%.3f\t%i\n", i[4], i[0].point_listings.count, i[3], i[1], i[0].id)
    end
  end

  task :fact_checking_discussion => :environment do 
    puts "Fact-checking metrics"


    impacts = []
    proposal_point_map = {}
    Point.where('comment_count > 0').each do |pnt|
      comts = pnt.comments.map {|x| x.created_at}.compact
      if !proposal_point_map.has_key? pnt.proposal.id
        proposal_point_map[pnt.proposal_id] = [comts]
      else
        proposal_point_map[pnt.proposal_id].push comts
      end
    end
    #pp proposal_point_map

    [0,1,2].each do |verdict|
      puts "For points with an overall " + verdict.to_s + " verdict"
      col = :overall_verdict
      #col = :max_verdict
      assessments = Assessable::Assessment.where(col => verdict)

      comments = { :before => 0, :after => 0 } 
      views = { :before => 0, :after => 0 }

      normalized_impact = 0
      cnt = 0


      assessments.each do |ass|
        pivot = ass.updated_at
        point = ass.root_object

        #next if point.comments.count == 0
        #next if ass.claims.count > 1
        #next if point.point_listings.where('created_at > "' + pivot.to_s + '"').count < 10

        comments_before_pivot = comments_after_pivot = 0.0

        proposal_point_map[point.proposal_id].each do |pnt|
          pnt.each do |comment|
            if comment < pivot
              comments_before_pivot += 1
            else  
              comments_after_pivot += 1
            end
          end 
        end

        point_before = point.comments.where('created_at < "' + pivot.to_s + '"').count.to_f / point.point_listings.where('created_at < "' + pivot.to_s + '"').count
        point_after = point.comments.where('created_at > "' + pivot.to_s + '"').count.to_f / point.point_listings.where('created_at > "' + pivot.to_s + '"').count
        point_after = point_after.infinite? ? 1.0 : point_after

        population_before = comments_before_pivot / point.proposal.point_listings.where('created_at < "' + pivot.to_s + '"').count
        population_after = comments_after_pivot / point.proposal.point_listings.where('created_at > "' + pivot.to_s + '"').count
        population_after = population_after.infinite? ? 1.0 : population_after

        
        next if point_after.nan?

        normalized_impact += (point_before > 0 ? point_after / point_before : 0) - (population_before > 0 ? population_after / population_before : 0)
        comments[:before] += point.comments.where('created_at < "' + pivot.to_s + '"').count
        comments[:after] += point.comments.where('created_at > "' + pivot.to_s + '"') .count
        views[:before] += point.point_listings.where('created_at < "' + pivot.to_s + '"').count
        views[:after] += point.point_listings.where('created_at > "' + pivot.to_s + '"').count
        cnt += 1

        impacts.push([point, normalized_impact, cnt, point.point_listings.where('created_at > "' + pivot.to_s + '"').count, verdict])

      end

      printf("%s:\tcomments %i\tviews %i\t%.3f\n", 'Before', comments[:before], views[:before], comments[:before].to_f / views[:before] )
      printf("%s:\tcomments %i\tviews %i\t%.3f\n", 'After', comments[:after], views[:after], comments[:after].to_f / views[:after] )

      printf("Impact:\t%.3f\n", (comments[:after].to_f / views[:after]) / (comments[:before].to_f / views[:before]) )
      printf("Normalized:\t%.3f\n", normalized_impact / cnt )
      pp cnt


    end

    impacts.sort! {|a,b| a[1] <=> b[1]}

    impacts.each do |i|
      printf("%i\t%i\t%i\t%.3f\t%i\n", i[4], i[0].point_listings.count, i[3], i[1], i[0].id)
    end
  end

  task :export_fact_checking => :environment do 

    election_date = DateTime.new(2012,11,8)

    Assessable::Assessment.find_each do |ass|
      #pp "Created at: #{ass.created_at}, Updated at: #{ass.updated_at}"
      #pp "requested at: #{ass.requests.first.created_at}"
    end
    # average_date = Assessable::Assessment.select('FROM_UNIXTIME(AVG(UNIX_TIMESTAMP(created_at) + (UNIX_TIMESTAMP(updated_at) - UNIX_TIMESTAMP(created_at))/2 )) as updated_at')
    # average_date = average_date[0].updated_at

    points = Assessable::Assessment.select('distinct(assessable_id)').map {|a| a.assessable_id }.compact

    proposals = points.map {|p| Point.find(p).proposal_id}.compact.uniq
    all_points = Point.where("proposal_id in (?) AND created_at < (?)", proposals, election_date)

    nf_inclusions_all = Inclusion.where("proposal_id in (?) and point_id not in (?)  AND created_at < (?)", proposals, points, election_date)

    nf_all_points = Point.where("proposal_id in (?)", proposals)
    is_pros = {}
    nf_all_points.each do |p|
      is_pros[p.id] = p
    end
    nf_comments_all = Comment.where("point_id in (?) and point_id not in (?) AND created_at < (?)", all_points.map {|p| p.id}.compact, points, election_date)

    nf_all_views = PointListing.where("point_id in (?) and point_id not in (?) and created_at is not null  AND created_at < (?)", all_points.map {|p| p.id}.compact, points, election_date)

    fc_inclusions_all = Inclusion.where("point_id in (?) AND created_at < (?)", points, election_date)

    fc_comments_all = Comment.where("point_id in (?) AND created_at < (?)", points, election_date)

    fc_all_views = PointListing.where("point_id in (?) and created_at is not null AND created_at < (?)", points, election_date)

    tmp = {}
    nf_all_views.each do |vw|
      if !tmp.has_key? [vw.point_id, vw.user_id]
        tmp[[vw.point_id,vw.user_id]] = vw
      end
    end
    nf_all_views = tmp.values()

    tmp = {}
    fc_all_views.each do |vw|
      if !tmp.has_key? [vw.point_id, vw.user_id]
        tmp[[vw.point_id,vw.user_id]] = vw
      end
    end
    fc_all_views = tmp.values()


    views_before = 0
    views_after = 0

    inclusions_before = 0
    inclusions_after = 0

    comments_after = 0
    comments_before = 0

    views_before0 = 0
    views_before1 = 0
    views_before2 = 0

    views_after0 = 0
    views_after1 = 0
    views_after2 = 0

    inclusions_before0 = 0
    inclusions_before1 = 0
    inclusions_before2 = 0

    inclusions_after0 = 0
    inclusions_after1 = 0
    inclusions_after2 = 0

    simulate_fact_check = true
    simulated_date = DateTime.new(2012,10,28)
    simulated_assessment = Assessable::Assessment.new(:updated_at => simulated_date, :overall_verdict => -1)
    simulated_request = Assessable::Request.new(:created_at => simulated_date)

    require 'csv'
    CSV.open("data.csv", "w") do |csv|

      head = ['firstview_timestamp', 'point_id', 'initiative_id', 'is_pro',  'was_point_factchecked', 'factchecked_before_view', 'fact_check_accuracy_verdict', 'first_request_timestamp', 'fact_check_timestamp', 'user_commented', 'user_commented_before_factcheck', 'user_commented_after_factcheck', 'user_included_point']


      csv << head
      [ [fc_all_views, true], [nf_all_views, false] ].each do |views, was_checked|
        views.each do |view|
          row = []

          # Time stamp for the view
          row.push view.created_at

          # An identifier for the point that was viewed
          row.push view.point_id

          #initiative_id
          row.push view.proposal_id

          #is_pro
          row.push is_pros[view.point_id].is_pro

          # An indicator for whether or not the point was ever fact checked (regardless of whether the particular view occurred before or after the fact check)
          row.push was_checked

          # An indicator for whether or not the point had been fact checked prior to the view
          assessment = Assessable::Assessment.find_by_assessable_id(view.point_id)
          if assessment
            request = assessment.requests.first
          end
          if simulate_fact_check && !was_checked
            assessment = simulated_assessment
            request = simulated_request
          end

          row.push was_checked || simulate_fact_check ? assessment.updated_at > view.created_at : nil

          # An indicator of the result of the fact check (if applicable) (using the 3 categories that you list in the table in Figure 2?)
          row.push was_checked || simulate_fact_check ? assessment.overall_verdict : nil

          # date of first request timestamp
          row.push was_checked || simulate_fact_check ? request.created_at : nil

          # date of fact check
          row.push was_checked || simulate_fact_check ? assessment.updated_at : nil

          comments = Comment.where(:point_id => view.point_id, :user_id => view.user_id)
          # An indicator for whether or not this viewer made a comment
          row.push comments.count > 0

          #made comment before fact check
          row.push was_checked || simulate_fact_check ? comments.where( "created_at < ?", assessment.updated_at).count > 0 : nil
          #made comment after fact check
          row.push was_checked || simulate_fact_check ? comments.where( "created_at >= ?", assessment.updated_at).count > 0 : nil

          # An indicator for whether or not the view resulted in an inclusion
          inclusion = Inclusion.where(:point_id => view.point_id, :user_id => view.user_id)
          row.push inclusion.count > 0

          # inclusion timestamp
          #row.push inclusion.count > 0 ? inclusion.first().created_at : nil

          if was_checked || simulate_fact_check
            viewed_before = assessment.updated_at > view.created_at

            if viewed_before then views_before += 1 else views_after += 1 end

            if assessment.overall_verdict == 0
              if viewed_before then views_before0 += 1 else views_after0 += 1 end
              if inclusion.count > 0 
                if viewed_before then inclusions_before0 += 1 else inclusions_after0 += 1 end
              end
            elsif assessment.overall_verdict == 1
              if viewed_before then views_before1 += 1 else views_after1 += 1 end
              if inclusion.count > 0 
                if viewed_before then inclusions_before1 += 1 else inclusions_after1 += 1 end
              end
            else
              if viewed_before then views_before2 += 1 else views_after2 += 1 end
              if inclusion.count > 0
                if viewed_before then inclusions_before2 += 1 else inclusions_after2 += 1 end
              end
            end

            if inclusion.count > 0
              if viewed_before then inclusions_before += 1 else inclusions_after += 1 end
            end
            if comments.count > 0
              if viewed_before then comments_before += 1 else comments_after += 1 end
            end
          end

          csv << row
        end
      end

      pp "Views Before: #{views_before}"
      pp "Views After: #{views_after}"

      pp "Inclusions Before: #{inclusions_before}"
      pp "Inclusions After: #{inclusions_after}"

      pp "Comments Before: #{comments_before}"
      pp "Comments After: #{comments_after}"

      pp 'INACCURATE'
      pp "Views Before: #{views_before0}"
      pp "Views After: #{views_after0}"

      pp "Inclusions Before: #{inclusions_before0}"
      pp "Inclusions After: #{inclusions_after0}"

      pp 'ACCURATE'
      pp "Views Before: #{views_before2}"
      pp "Views After: #{views_after2}"

      pp "Inclusions Before: #{inclusions_before2}"
      pp "Inclusions After: #{inclusions_after2}"


    end

  end

  task :data_for_fact_checking_timeseries => :environment do 

    assessed_points = Assessable::Assessment.select('distinct(assessable_id)').map {|a| a.assessable_id }.compact

    proposals = assessed_points.map {|p| Point.find(p).proposal_id}.compact.uniq

    requests = Assessable::Request.all.map {|r| r.created_at}
    assessments = Assessable::Assessment.all.map {|a| a.updated_at}
    points = Point.published.where("proposal_id in (?)", proposals).map {|p| p.created_at}

    days = {}

    points.each do |p|
      day = p.strftime('%F')
      if !days.has_key? day
        days[day] = {:point => 0, :requests => 0, :assessments => 0}
      end
      days[day][:point] += 1
    end

    requests.each do |p|
      day = p.strftime('%F')
      if !days.has_key? day
        days[day] = {:point => 0, :requests => 0, :assessments => 0}
      end
      days[day][:requests] += 1
    end

    assessments.each do |p|
      day = p.strftime('%F')
      if !days.has_key? day
        days[day] = {:point => 0, :requests => 0, :assessments => 0}
      end
      days[day][:assessments] += 1
    end    

    ordered_days = days.keys().sort()
    cumulative = []
    pp ordered_days

    ordered_days.each_with_index do |day, idx|
      if cumulative.length == 0
        cumulative.push [day, days[day][:point], days[day][:requests], days[day][:assessments]]
      else
        pp cumulative
        cumulative.push [day, days[day][:point] + cumulative[idx-1][1] , days[day][:requests] + cumulative[idx-1][2], days[day][:assessments] + cumulative[idx-1][3]]
      end
    end

    require 'csv'
    CSV.open("data_time.csv", "w") do |csv|

      head = ['date', 'points',  'requests', 'assessments']


      csv << head
      cumulative.each do |data|
        csv << data

      end
    end

  end


  task :referer => :environment do 
    puts "User referals"
    year = 2012
    users = User.where(:account_id => 1).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')

    domains = {}

    users.each do |user|
      begin
        domain = URI.parse(user.referer).host
        if user.referer.index('aclk')
          domain = 'google.ads.com'
        end
      rescue
        domain = nil
      end


      if !domains.has_key?(domain)
        domains[domain] = {:users => 0, :opinions => 0, :points => 0, :inclusions => 0}
      end
      domains[domain][:users] += 1 
      domains[domain][:opinions] += user.opinions.published.where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').count
      domains[domain][:points] += user.points.published.where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').count      
      domains[domain][:inclusions] += user.inclusions.where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins('INNER JOIN opinions ON inclusions.user_id=opinions.user_id AND inclusions.proposal_id=opinions.proposal_id').where('opinions.published = 1').count
      #domains[domain][:comments] += user.comments.where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').count      
    end

    as_array = []; domains.each {|k,vs| as_array.push([k,vs]) }  

    puts( "Domain\tusers\topinions\tinclusions\tpoints")
    as_array.sort{|x,y| x[1][:users]<=>y[1][:users]}.each do |domain|
        printf("%s\t%i\t%i\t%i\t%i\n",

        domain[0], 
        domain[1][:users],
        domain[1][:opinions],
        domain[1][:inclusions],
        domain[1][:points]
        #domain[:comments]
      )
    end
  end

















end