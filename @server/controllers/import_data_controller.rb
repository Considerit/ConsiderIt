require 'csv'
require 'zip'


# Imports data from CSVs
# Limitations:
#   - can only import comments if they refer to a point described in this batch

class ImportDataController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def create

    authorize! 'update subdomain'

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


          CSV.foreach(file.tempfile, :headers => true, 
            :encoding => encoding, 
            :header_converters=> lambda {|f| f.strip},
            :converters => lambda {|f| f ? f.strip : nil}) do |row|

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

              if row['user']
                user = User.find_by_email(row['user'].downcase)
              else
                user = nil
              end

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

                attrs['password'] = row.has_key?('password') ? row['password'] : SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20] 
                user = User.new attrs
                user.registered = true
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
              attrs['roles'] = "{\"editor\":[\"/user/#{user.id}\"], \"writer\":[\"*\"], \"commenter\":[\"*\"], \"opiner\":[\"*\"], \"observer\":[\"*\", \"*\"]}"

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
              point = proposal.points.find_by_nutshell(attrs['nutshell'])
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

  def export
    subdomain = current_subdomain

    export_path = "lib/tasks/client_data/export/"

    CSV.open("#{export_path}#{subdomain.name}-opinions.csv", "w") do |csv|
      csv << ["proposal_slug","proposal_name", 'created', "username", "email", "opinion", "#points"]
    end

    CSV.open("#{export_path}#{subdomain.name}-points.csv", "w") do |csv|
      csv << ['proposal', 'type', 'created', "username", "author", "valence", "summary", "details", 'author_opinion', '#inclusions', '#comments']
    end

    fields = {}
    subdomain.users.each do |user|
      if !user.super_admin
        for k,v in JSON.parse(user.tags) or {}
          fields[k.split('.')[0]] = 1
        end
      end
    end 
    fields = fields.keys()

    #fields = "zip", "gender", "age", "ethnicity", "education", "race", "home", "hispanic", "hala_focus_group"
    CSV.open("#{export_path}#{subdomain.name}-users.csv", "w") do |csv|

      row = ['email', 'name', 'date joined'] 
      for field in fields 
        row.append field 
      end 
      csv << row
    end


    CSV.open("#{export_path}#{subdomain.name}-proposals.csv", "w") do |proposals_csv|
      proposals_csv << ['slug', 'created', "username", "author", 'name', 'description', '#points', '#opinions', 'total_score', 'avg_score']

      subdomain.proposals.each do |proposal|

        opinions = proposal.opinions.published
        total_score = 0
        opinions.each do |o|
          total_score += o.stance
        end

        begin 
          avg_score = total_score / opinions.count
        rescue
          avg_score = 0 
        end 

        proposals_csv << [proposal.slug, proposal.created_at, proposal.user.name, proposal.user.email.gsub('.ghost', ''), proposal.name, proposal.description, proposal.points.published.count, opinions.count, total_score, avg_score]

        CSV.open("#{export_path}#{subdomain.name}-opinions.csv", "a") do |csv|
          proposal.opinions.published.each do |opinion|
            user = opinion.user
            begin 
              csv << [proposal.slug, proposal.name, opinion.created_at, user.name, user.email.gsub('.ghost', ''), opinion.stance, user.points.where(:proposal_id => proposal.id).count]
            rescue 
            end 
          end
        end

        CSV.open("#{export_path}#{subdomain.name}-points.csv", "a") do |csv|

          proposal.points.published.each do |pnt|
            begin 
              opinion = pnt.user.opinions.find_by_proposal_id(pnt.proposal.id)
              csv << [pnt.proposal.slug, 'POINT', pnt.created_at, pnt.hide_name ? 'ANONYMOUS' : pnt.user.name, pnt.hide_name ? 'ANONYMOUS' : pnt.user.email.gsub('.ghost', ''), pnt.is_pro ? 'Pro' : 'Con', pnt.nutshell, pnt.text, opinion ? opinion.stance : '-', pnt.inclusions.count, pnt.comments.count]

              pnt.comments.each do |comment|
                opinion = comment.user.opinions.find_by_proposal_id(pnt.proposal.id)
                csv << [pnt.proposal.slug, 'COMMENT', comment.created_at, comment.user.name, comment.user.email.gsub('.ghost', ''), "", comment.body, '', opinion ? opinion.stance : '-', '', '']
              end
            rescue 
            end 
          end
        end
      end
    end

    subdomain.users.each do |user|
      CSV.open("#{export_path}#{subdomain.name}-users.csv", "a") do |csv|
        tags = {}
        for k,v in JSON.parse(user.tags) or {}
          if k == 'age.editable' && ['hala','engageseattle'].include?(subdomain.name)
            if v.to_i > 0          
              v = v.to_i

              if v < 20
                v = '0-20'
              elsif v > 70
                v = '70+'
              else 
                v = "#{10 * ((v / 10).floor)}-#{10 * ((v / 10).floor + 1)}"
              end 
            else 
              next 
            end
          end 
          tags[k.split('.')[0]] = v
        end

        row = [user.email, user.name, user.created_at]
        for field in fields

          row.append tags.has_key?(field) ? tags[field] : ""
        end
        csv << row
      end
    end

    zip_path = "#{export_path}#{subdomain.name}.zip"
    Zip::File.open(zip_path, Zip::File::CREATE) do |z|

      files = [
        "#{subdomain.name}-opinions.csv",
        "#{subdomain.name}-points.csv",
        "#{subdomain.name}-users.csv",
        "#{subdomain.name}-proposals.csv"
      ]

      files.each do |fname|
        f = CSV.open(export_path + fname, 'a')
        z.add(fname, f.path)
      end

    end 

    send_file zip_path, type: 'application/zip',
      disposition: 'attachment',
      filename: "#{current_subdomain.name}-data.zip"

  end


end