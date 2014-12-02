require 'csv'


# Imports data from CSVs
# Limitations:
#   - can only import comments if they refer to a point described in this batch

class ImportDataController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def create
    if !access
      raise new CanCan::AccessDenied
    end

    errors = []
    modified = {}

    if current_subdomain.name == 'livingvotersguide'
      import_for_LVG(errors, modified)
    else
      points = {}
      proposals = []

      configuration = {
        'users' => {
          required_fields: ['name', 'email'],
          directly_extractable: ['name', 'email']
        },
        'proposals' => {
          required_fields: ['url', 'topic', 'user'],
          directly_extractable: ['description', 'cluster', 'seo_title', 'seo_description', 'seo_keywords', 'description_fields']
        },
        'opinions' => {
          required_fields: ['user', 'proposal', 'stance'],
          directly_extractable: ['stance']
        },
        'points' => {
          required_fields: ['id', 'user', 'proposal', 'nutshell', 'is_pro'],
          directly_extractable: ['nutshell', 'text']
        },      
        'comments' => {
          required_fields: ['user', 'point', 'body'],
          directly_extractable: ['body']
        }
      }


      # wrap everything in a transaction so that we can rollback _everything_ in the case of errors
      ActiveRecord::Base.transaction do


        # Now loop back through to create objects
        # The order of the tables matters
        for table in ['users', 'proposals', 'opinions', 'points', 'comments']
          file = params["#{table}-file"]
          next if !file || file == ''

          modified[table] = []

          config = configuration[table]
          checked_required_fields = false

          begin
            CSV.read(file.tempfile)
            encoding = 'utf-8'
          rescue
            encoding = 'windows-1251:utf-8'
          end


          CSV.foreach(file.tempfile, :headers => true, :encoding => encoding) do |row|
            error = false

            # Make sure that this file has all the required columns           
            if !checked_required_fields
              missing_fields = []
              config[:required_fields].each do |rq|
                if !row.has_key?(rq)
                  missing_fields.append rq
                end 
              end
              if missing_fields.length > 0 
                # not worth continuing to parse if required fields are missing in the schema
                errors.append "#{table} file is missing required columns: #{missing_fields.join(', ')}"
                break
              else 
                checked_required_fields = true
              end
            end

            # Make sure this row has values for each required field
            empty_required_fields = []
            config[:required_fields].each do |rq|
              if row[rq] == ''
                empty_required_fields.append rq
              end
            end
            if empty_required_fields.length > 0
              error = true
              errors.append "#{table} file has some empty entries for the #{rq} field"
            end

            # Find each required relational object
            if config[:required_fields].include? 'user'
              user = User.find_by_email(row['user'].downcase)
              if !user
                errors.append "#{table} file: could not find a User with an email #{row['user']}. Did you forget to add #{row['user']} to the User file?"
                error = true
              end
            end

            if config[:required_fields].include? 'proposal'
              proposal = Proposal.find_by_slug(row['proposal'].gsub(' ', '_').gsub(',','_').gsub('.','').downcase)
              if !proposal
                errors.append "#{table} file: could not find a Proposal associated with #{row['proposal']}. Did you forget to add #{row['proposal']} to the Proposal file?"
                error = true
              end
            end

            if config[:required_fields].include? 'point'
              # Comments will refer to a point by a made up id field. Points are indexed by their 
              # ID in the points hash. These IDs do not correspond to the database. Comments
              # for now can only be added to points that are identified in the same batch of uploaded CSVs.
              
              point = points.has_key?(row['point']) ? points[row['point']] : nil
              if !point
                errors.append "#{table} file: could not find a Point associated with #{row['point']}. Did you forget to add a Point with id #{row['point']} to the Point file?"
                error = true
              end
            end

            next if error

            # Grab all of the easily extracted attributes
            attrs = row.to_hash.select{|k,v| config[:directly_extractable].include? k}

            # The rest has to be handled on a table by table basis
            case table
            when 'users'
              user = User.find_by_email row['email'].downcase

              if row.has_key? 'avatar'
                attrs['avatar_url'] = row['avatar']
              elsif params[:assign_pics]
                attrs['avatar_url'] = "https://dl.dropboxusercontent.com/u/3403211/demofaces/#{Random.rand(1..120)}.jpg"
              end

              if !user
                attrs['password'] = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] 
                user = User.new attrs
                user.save
                modified[table].push "Created User '#{user.name}'"
              else 
                user.update_attributes attrs
                modified[table].push "Updated User '#{user.name}'"              
              end
              user.add_to_active_in

            when 'proposals'

              attrs.update({
                'slug' => row['url'].gsub(' ', '_').gsub(',','_').gsub('.','').downcase,
                'user_id' => user.id,
                'name' => row['topic'],
                'published' => true
              })

              proposal = Proposal.find_by_slug attrs['slug']
              if !proposal
                attrs['subdomain_id'] = current_subdomain.id
                proposal = Proposal.new attrs
                proposal.save
                modified[table].push "Created Proposal '#{proposal.slug}'"
              else
                proposal.update_attributes attrs
                modified[table].push "Updated Proposal '#{proposal.slug}'"              
              end

              proposals.push proposal



            when 'opinions'
              opinion = Opinion.where(:user_id => user.id, :proposal_id => proposal.id).first
              attrs.update({
                'proposal_id' => proposal.id,
                'user_id' => user.id,
              })

              # we'll assume that if we're creating an opinion for a user that the user should 
              # be registered
              if !user.registered
                user.registered = true
                user.save
              end

              if !opinion
                attrs['subdomain_id'] = current_subdomain.id
                opinion = Opinion.new attrs
                opinion.publish
                modified[table].push "Created Opinion by #{user.name} on '#{proposal.name}'"
              else
                opinion.update_attributes attrs
                opinion.recache
                modified[table].push "Updated Opinion by #{user.name} on '#{proposal.name}'"
              end

            when 'points'

              opinion = Opinion.where(:user_id => user.id, :proposal_id => proposal.id).first
              if !opinion
                errors.push "A Point written by #{user.email} does not have an associated Opinion. Please add an Opinion for this user to the Opinions file!"
                next
              end

              if !row['is_pro']
                errors.push "A Point written by #{user.email} isn't specified as a pro or con."
                next
              end

              attrs.update({
                          'proposal_id' => proposal.id,
                          'user_id' => user.id,
                          'published' => true,
                          'is_pro' => ['1', 'true'].include?(row['is_pro'].downcase)
                        })
              point = Point.find_by_nutshell(attrs['nutshell'])
              if !point
                attrs['subdomain_id'] = current_subdomain.id
                point = Point.new attrs
                point.save
                modified[table].push "Created Point '#{point.nutshell}'"
              else
                point.update_attributes attrs
                modified[table].push "Updated Point '#{point.nutshell}'"
              end

              opinion.include point
              point.recache
              points[row['id']] = point
              

            when 'comments'
              attrs.update({
                'point_id' => point.id,
                'user_id' => user.id,
                'commentable_type' => 'Point',
                'commentable_id' => point.id
              })

              comment = Comment.where(:point_id => point.id, :user_id => user.id, :body => attrs['body'] ).first
              if !comment
                attrs['subdomain_id'] = current_subdomain.id
                comment = Comment.new attrs
                comment.save
                modified[table].push "Created Comment '#{comment.body}'"
              else 
                comment.update_attributes attrs
                modified[table].push "Updated Comment '#{comment.body}'"
              end
              point.recache

            end
          end

        end

        if errors.length > 0
          Thread.current[:dirtied_keys] = {}
          raise ActiveRecord::Rollback
        end

        if params[:generate_inclusions] && proposals.length > 0
          ['users', 'opinions'].each do |t|
            if !modified.include? t
              modified[t] = []
            end
          end
          proposals.each do |proposal|
            # Get all into a distribution of stances. We'll generate opinions 
            # in a way roughly consistent with the existing 
            # distribution shape. 
            opinions = proposal.opinions.published.map {|o| o.stance}

            included_pros = proposal.inclusions.map {|i| i.point.is_pro && i.point.published ? i.point_id : nil}.compact
            included_cons = proposal.inclusions.map {|i| !i.point.is_pro && i.point.published ? i.point_id : nil}.compact


            # We'll double the number of opinions, basing the new
            # opinion around an existing opinion. 
            opinions.each do |target_stance| 

              ####
              # Create a fake user for this opinion
              new_id = User.last.id + 1
              attrs = {
                'name' => "Fake User #{new_id}",
                'email' => "#{new_id}@ghost.dev",
                'password' => SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20],
                'registered' => true,
                'avatar_url' => "https://dl.dropboxusercontent.com/u/3403211/demofaces/#{Random.rand(1..120)}.jpg"
              }
              user = User.create! attrs
              user.add_to_active_in
              modified['users'].push "Created User '#{user.name}'"

              ####
              # Generate a stance for this user, based around the target_stance (+/- .1)
              new_stance = target_stance + Random.rand(-1.0..1.0) * 0.2
              if new_stance < -1
                new_stance = -1
              elsif new_stance > 1
                new_stance = 1
              end

              opinion = Opinion.create!({
                :subdomain_id => current_subdomain.id,
                :proposal_id => proposal.id,
                :user_id => user.id,
                :stance => new_stance,
                :published => true
                })

              ###
              # Generate two point inclusions for this user, biased toward their stance
              if included_pros.length > 0 && included_cons.length > 0
                inclusions = []
                [0,1].each do |iter|
                  if Random.rand(-3.0..3.0) + new_stance > 0
                    # select a pro (already biased toward most included points)
                    list = included_pros
                  else
                    list = included_cons
                  end

                  point = list.sample
                  inclusions.push point
                  list.push point
                end

                opinion.update_inclusions inclusions
                opinion.point_inclusions = JSON.dump(inclusions)
                opinion.save
              end
              modified['opinions'].push "Created Opinion by #{user.name} on '#{proposal.name}'"
            end
          end


        end
      end
    end

    if errors.length > 0
      render :json => [{'errors' => errors.uniq}]
    else
      # Point.delay.update_scores
      render :json => [modified]
    end

  end

  private

  def access
    return current_user.is_admin?
  end

  # These are LVG-specific data imports. Unfortunately we have to maintain them!
  def import_for_LVG(errors, modified)

    subdomain = Subdomain.find_by_name('livingvotersguide')

    #########################
    # Import ballot measures
    file = params["measures-file"]
    if file && file != ''
      begin
        CSV.read(file.tempfile)
        encoding = 'utf-8'
      rescue
        encoding = 'windows-1251:utf-8'
      end

      modified['measures'] = []


      CSV.foreach(file.tempfile, :headers => true, :encoding => encoding) do |row|
        jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')

        slug = row['topic']
        if row['category'] && row['designator']
          slug = "#{row['category'][0]}-#{row['designator']}_#{slug}"
        end

        if jurisdiction != 'Statewide'
          slug += "-#{jurisdiction}"
        end

        slug = slug.gsub(' ', '_').gsub(',','_').gsub('.','')

        pp slug

        description_fields = []    

        explanatory_statement = row.fetch('explanatory statement', nil)
        fiscal_impact = row.fetch('fiscal impact', nil)

        if explanatory_statement || fiscal_impact
          group = {
            :group => "Provided by state of WA",
            :items => []
          }
          state_data = [ [explanatory_statement, 'Explanatory statement by Office of Attorney General'], \
                         [fiscal_impact, 'Fiscal Impact Statement by Office of Financial Management']]
          state_data.each do |field|
            if field[0]
              field[0] = parse(field[0])
              group[:items].push({:label => field[1], :html => field[0]})
            end
          end
          description_fields.push group
        end

        if additional_description = row.fetch('additional_description', nil)
          description_fields = [{:label => 'Additional information', :html => parse(additional_description)}] 
        end

        description = row['description'].encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        if row['maplight_id'] && row['maplight_id'].length > 0
          description, more_description_fields = fetchAndParseMeasureFromMaplight row['maplight_id']
          description_fields += more_description_fields        
          # NOTE: preferring Maplight's description over our own. 
        end

        if row.fetch('url', nil)
          description += " Read the <a href='#{row['url']}' target='_blank'>full text</a>."
        end

        category = row['category']
        if jurisdiction == 'Statewide'
          if category == 'Advisory Measure'
            cluster = 'Advisory votes'
          else
            cluster = 'Statewide measures'
          end

        else 
          cluster = jurisdiction
        end

        measure = {
          :subdomain_id => subdomain.id,
          :user_id => 1, 
          :slug => slug,
          :name => row['topic'],
          :category => category,
          :designator => row['designator'],
          :description => description,
          :published => true, 
          :cluster => cluster,
          :description_fields => description_fields.length > 0 ? JSON.dump(description_fields) : nil,
          :seo_title => row.fetch('seo_title', nil),
          :seo_description => row.fetch('seo_description', nil),
          :seo_keywords => row.fetch('seo_keywords', nil)
        }

        proposal = Proposal.find_by_slug slug
        if !proposal
          proposal = Proposal.new measure
          proposal.save
          #pp "Added #{row['topic']}: #{slug}"
          modified['measures'].push "Created Measure '#{proposal.slug}'"

        else
          measure.delete :subdomain_id
          proposal.update_attributes measure
          modified['measures'].push "Updated Measure '#{proposal.slug}'"
        end

      end
    end


    #########################
    # Import candidates
    file = params["candidates-file"]
    if file && file != ''
      begin
        CSV.read(file.tempfile)
        encoding = 'utf-8'
      rescue
        encoding = 'windows-1251:utf-8'
      end

      modified['candidates'] = []
      CSV.foreach(file.tempfile, :headers => true, :encoding => encoding) do |row|

        candidate_id = row['maplight_id']
        data = fetchFromMaplight("cvg.candidate_v1.json?candidate_id=#{candidate_id}&data_type=all")
        jurisdiction = data['contest']['title'].gsub(' - Washington', '').gsub('U.S. Representative', 'Congressional')
        name = data['display_name']
        slug = "#{name}-washington_#{jurisdiction}".gsub(' ', '_').downcase

        # pp data['summary']['summary_items'].map {|i| i.keys()}
        #pp jurisdiction, name, slug

        contest_description = "U.S. #{data['contest']['office']['body']}"
        gender = data['gender'] == 'F' ? 'Her' : 'His'

        description = "#{name} is a #{data['party']} candidate seeking to represent Washington's #{jurisdiction} in the #{contest_description}."

        description_fields = data['summary']['summary_items'].map {|item| {:label => item['title'].downcase.capitalize, :html => item['yes_text'].gsub('Not Applicable', 'None found')} }

        funding_html = ""

        if data['funding'] &&  (data['funding']['support'] && data['funding']['support']['items'] != nil)
          funders = data['funding']['support']

          if funders && funders['items'] && funders['items'].length > 0

            endorser_type = "<span style='float:none' class='total_money_raised'>#{number_to_currency(funders['grand_total'], :precision => 0)}</span>"
            funding_html += "<div class='funders support'><div style='text-align: right'>#{endorser_type}</div><ul>"
          
            for funder in funders['items'][0..10]
              funding_html += "<li><span class='funder_name'>#{funder['name'].split.map(&:capitalize).join(' ').gsub('Llc', 'LLC')}</span><span class='funder_amount'>#{number_to_currency(funder['amount'], :precision => 0)}</span></li>"
            end
            if funders['items'].length > 10
              funding_html += "<li class='other_donors'>...#{funders['items'].length - 10} other donors</li>"
            end
          else
            funding_html += "<div style='font-style: italic'>No donations in Support yet<ul>"
          end
          funding_html += "</ul></div>"
        end

        
        if funding_html != ""
          description_fields.append({
                    :label => 'Donors', 
                    :html => "<div>#{funding_html}</div>"
                  })
        end

        measure = {
          :subdomain_id => subdomain.id,
          :user_id => 1, 
          :slug => slug,
          :name => name,
          :description => description,
          :published => true,
          :cluster => jurisdiction,
          :description_fields => description_fields.length > 0 ? JSON.dump(description_fields) : nil,
          :seo_title => "#{name}, Candidate for Washington #{jurisdiction}",
          :seo_description => description,
          :seo_keywords => "washington,state,us,congressional,2014,#{name}"
        }

        #proposal = Proposal.find_by_slug slug
        proposal = Proposal.find_by_slug slug
        if !proposal
          proposal = Proposal.new measure
          proposal.save
          modified['candidates'].push "Created Candidate '#{proposal.name}'"
        else
          measure.delete :subdomain_id
          proposal.update_attributes measure
          modified['candidates'].push "Updated Candidate '#{proposal.name}'"
        end

      end
    end

    #########################
    # Import jurisdictions
    file = params["jurisdictions-file"]
    if file && file != ''
      begin
        CSV.read(file.tempfile)
        encoding = 'utf-8'
      rescue
        encoding = 'windows-1251:utf-8'
      end
      modified['jurisdictions'] = []

      jurisdiction_to_proposals = {}

      proposals = subdomain.proposals.where('cluster is not null')
      proposals.each do |p|
        jurisdiction_to_proposals[p.cluster] = [] if !(jurisdiction_to_proposals.has_key?(p.cluster))
        jurisdiction_to_proposals[p.cluster].append p
      end

      jurisdiction_to_zips = {}
      CSV.foreach(file.tempfile, :headers => true, :encoding => encoding) do |row|
        jurisdiction = row['jurisdiction'].split.map(&:capitalize).join(' ')
        if !jurisdiction_to_zips.has_key?(jurisdiction)
          jurisdiction_to_zips[jurisdiction] = []
        end
        jurisdiction_to_zips[jurisdiction].push row['zip'].to_i
      end

      jurisdiction_to_proposals.each do |jurisdiction, proposals|
        jurisdiction = jurisdiction.split.map(&:capitalize).join(' ')
        next if ['Advisory Votes', 'Statewide Measures'].include?(jurisdiction)
        zips = jurisdiction_to_zips[jurisdiction]
        if !jurisdiction_to_zips.has_key?(jurisdiction)
          errors.push "ERROR: jurisdiction #{jurisdiction} not found!...skipping"
          next
        end
        #pp "For #{jurisdiction}, adding #{zips.length} zips to #{proposals.length} measures"

        proposals.each do |p|
          p.hide_on_homepage = true
          p.zips = JSON.dump zips
          #pp p.zips
          p.save
        end
        modified['jurisdictions'].push "Added zips for jurisdiction '#{jurisdiction}'"

      end
    end
    #####################

  end

  def parse(html)
    #HTML::WhiteListSanitizer.allowed_css_properties = Set.new(%w(text-align font-weight text-decoration font-style))
    parsed = ActionController::Base.helpers.sanitize(html.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''), tags: %w(table tr td div p br label ul li ol span strong h1 h2 h3 h4 h5), attributes: %w(id colspan) )  
    parsed = parsed.gsub('<p>&nbsp;</p>', '')
  end

  def fetchFromMaplight(url)
    maplight_api_key = '1e6bae2f57efdf70d3bc198bd6b89869'
    root = 'http://votersedge.org/services_open_api/'
    url = "#{root}#{url}&apikey=#{maplight_api_key}"
    pp "Fetching #{url}"
    results = ""
    endpoint = open(url, :http_basic_authentication => ['beta', 'beta']) do |f|
      f.each_line {|line| 
        results = "#{results}#{line}" unless line[0] == '<'
      }
    end 
    JSON.parse(results)
  end

  def fetchAndParseMeasureFromMaplight(measure_id)
    data = fetchFromMaplight "cvg.measure_v1.json?measure_id=#{measure_id}&data_type=all"
    
    funding_html = ""
    endorsement_html = ""
    editorial_html = ""
    news_html = ""

    if data['funding'] && ( (data['funding']['oppose'] && data['funding']['oppose']['items'] != nil) || (data['funding']['support'] && data['funding']['support']['items'] != nil) )
      [ data['funding']['support'], data['funding']['oppose'] ].each_with_index do |funders, idx|

        if funders && funders['items'] && funders['items'].length > 0

          endorser_type = "Donations in #{idx == 0 ? 'Support' : 'Opposition'} <span class='total_money_raised'>#{number_to_currency(funders['grand_total'], :precision => 0)}</span>"
          funding_html += "<div class='endorser_group funders #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"
        
          for funder in funders['items'][0..10]
            funding_html += "<li><span class='funder_name'>#{funder['name'].split.map(&:capitalize).join(' ').gsub('Llc', 'LLC')}</span><span class='funder_amount'>#{number_to_currency(funder['amount'], :precision => 0)}</span></li>"
          end
          if funders['items'].length > 10
            funding_html += "<li class='other_donors'>...#{funders['items'].length - 10} other donors</li>"
          end
        else
          funding_html += "<div style='font-style: italic'>No donations in #{idx == 0 ? 'Support' : 'Opposition'} yet<ul>"
        end
        funding_html += "</ul></div>"
      end
    end

    if data['endorsements'] && ((data['endorsements']['support'] != [nil] && data['endorsements']['support'].length > 0) || (data['endorsements']['oppose'] != [nil] && data['endorsements']['oppose'].length > 0))
      [ data['endorsements']['support'], data['endorsements']['oppose'] ].each_with_index do |endorsers, idx|
        
        endorser_type = idx == 0 ? 'This measure is endorsed by:' : 'This measure is opposed by:' 
        endorsement_html += "<div class='endorser_group endorsements #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><p>"
        if endorsers.length == 0 || endorsers == [nil]
          endorsement_html += "<span style='font-style: italic'>No endorsers yet</span>"
        else
          for endorsement in endorsers
            if endorsement['url'] && endorsement['url'].length > 0
              endorsement_html += "<a href='#{endorsement['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{endorsement['title']}</a>, "
            else
              endorsement_html += "<span>#{endorsement['title']}</span>, "
            end

          end
          endorsement_html = endorsement_html[0..endorsement_html.length-3]
        end
        endorsement_html += "</p></div>"

      end
    end

    if data['editorials'] && ((data['editorials']['support'] && data['editorials']['support'].length > 0) || (data['editorials']['oppose'] && data['editorials']['oppose'].length > 0))
      [ data['editorials']['support'], data['editorials']['oppose'] ].each_with_index do |editorials, idx|
        endorser_type = idx == 0 ? 'Supporting this measure:' : 'Opposing this measure:' 
        editorial_html += "<div class='endorser_group editorials #{idx == 0 ? 'support' : 'oppose'}'><div>#{endorser_type}</div><ul>"
        if (editorials && editorials.length > 0)
          for editorial in editorials
            editorial_html += "<li><a href='#{editorial['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{editorial['headline']}</a><br>#{editorial['outlet']}, #{editorial['date']}</li>"
          end
        else
          editorial_html += "<li style='font-style: italic'>None written yet</li>"
        end
        editorial_html += "</ul></div>"
      end
    end

    if data['news'] 
      stories = data['news']
      stories.delete 'source'
      if stories.values().length > 0  
        news_html += "<ul class='news'>"
        for story in data['news'].values()
          news_html += "<li><a href='#{story['url']}' rel='nofollow' target='_blank' style='text-decoration:underline'>#{story['headline']}</a><br>#{story['outlet']}, #{story['date']}</li>"
        end
        news_html += "</ul>"
      end
    end
    description_fields = []

    if funding_html + endorsement_html + editorial_html != ""
      group = ({
        :group => "Who supports each side?",
        :items => []
      })

      if funding_html + endorsement_html != ""
        group[:items].append({
                :label => 'Funding and endorsements', 
                :html => "<div>#{funding_html}</div><div>#{endorsement_html}</div>"
              })
      end

      if editorial_html != ""
        group[:items].append({
                :label => 'Editorials', 
                :html => editorial_html
              })
      end

      description_fields.append group

    end

    if news_html != ''
      description_fields.append({
        :group => "Media coverage",
        :items => [{:label => 'News stories and debates', :html => news_html}]
      })
    end


    return [data['summary']['main_summary'], description_fields]

  end


end