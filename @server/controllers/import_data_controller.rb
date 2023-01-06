require 'csv'
require 'zip'

require 'data_exports'
include Exports

EXPORT_PATH = "lib/tasks/client_data/export/"

# Imports data from CSVs
# Limitations:
#   - can only import comments if they refer to a point described in this batch

class ImportDataController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def create

    authorize! 'update subdomain'

    errors = []
    modified = {}

    points = {}
    proposals = []

    configuration = {
      'users' => {
        required_fields: ['name', 'email'],
        directly_extractable: ['name', 'email', 'tags']
      },
      'proposals' => {
        required_fields: ['title'],
        directly_extractable: ['description', 'cluster', 'seo_title', 'seo_description', 'seo_keywords', 'json']
      },
      'opinions' => {
        required_fields: ['user', 'proposal', 'stance'],
        directly_extractable: ['stance']
      },
      'points' => {
        required_fields: ['user', 'proposal', 'is_pro'],
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

        encoding = nil
        worked = false
        ['utf-8', 'windows-1251:utf-8', 'windows-1256:utf-8'].each do |enc|
          encoding = enc
          begin 
            CSV.read(file.tempfile, :encoding => encoding)
            worked = true
          rescue
          end
          break if worked
        end

        pp "******", encoding, worked

        CSV.foreach(file.tempfile, :headers => true, 
          :encoding => encoding, 
          :header_converters=> lambda {|f| f.strip},
          :converters => lambda {|f| f ? f.strip : nil}) do |row|

          error = false

          # Make sure that this file has all the required columns           
          if !checked_required_fields
            missing_fields = []
            config[:required_fields].each do |rq|
              fields = rq.split('|')
              has_one = false
              fields.each do |fld|
                has_one ||= row.has_key?(fld)
              end
              if !has_one
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
            errors.append "#{table} file has some empty entries for #{empty_required_fields.join(', ')} field(s)"
          end

          # Find each required relational object
          if config[:required_fields].include?('user') || row.has_key?('user')
            user = nil 
            if row['user']
              user = User.find_by_email(row['user'].downcase)
            end

            if !user && table == 'proposals'
              user = current_user  # default to person who is importing the data
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

          if config[:required_fields].include? 'stance'
            if row['stance'] == nil || row['stance'].to_f < -1 || row['stance'].to_f > 1
              errors.append "#{table} file: invalid stance for user #{row['user']} and proposal #{row['proposal']}"
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
            if !row['email'] || row['email'].length < 3
              errors.push "Could not import User #{row} because email isn't present"
              next
            end
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

            customizations = current_subdomain.customization_json
            tags_config = customizations.fetch('user_tags', [])
            tags_config.each do |vals|
              tag = vals["key"]
              if row.has_key? tag
                user.tags ||= {}
                user.tags[tag] = row[tag]
              end
              user.save
            end

            user.add_to_active_in

          when 'proposals'

            title = row.fetch('title', false) || row.fetch('name', false)
            list = row.fetch('group', false) || row.fetch('topic', false) || row.fetch('list', false) || row.fetch('cluster', false) || row.fetch('category', false)

            if !user 
              user = current_user
            end

            next if !title

            if list
              customizations = current_subdomain.customization_json
              customizations.each do |k,v|
                if k.match( /list\// )
                  if v.has_key?('list_title') && v['list_title'] == list
                    list = k.split('/')[-1]
                  end
                end
              end
            end

            slug = nil 
            if row.has_key? 'url'
              slug = slugify(row['url'])
              proposal = Proposal.find_by_slug slug 
            else
              if list
                proposal = Proposal.where(:name => title, :cluster => list).first
              else 
                proposal = Proposal.find_by_name(title)
              end

              if row.has_key? 'slug'
                slug = row['slug']
              end
            end

            attrs.update({
              'slug' => slug,
              'user_id' => user.id,
              'name' => title,
              'published' => true
            })

            if list
              attrs['cluster'] = list
            end

            attrs['roles'] = {
              "editor": ["/user/#{user.id}"]
            }

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

            if !row['nutshell'] || row['nutshell'].length == 0 
              # disabling error for this case just for the bronx use case 
              pp "A Point written by #{user.email} for Proposal #{proposal.slug} does not have a nutshell. Please add text for a nutshell for this user to the Points file!"
              # errors.push "A Point written by #{user.email} for Proposal #{proposal.slug} does not have a nutshell. Please add text for a nutshell for this user to the Points file!"
              next              
            end

            if row['nutshell'].length > 180
              if row['text'] && row['text'].length > 0 
                errors.push "A Point written by #{user.email} for Proposal #{proposal.slug} has a nutshell that is greater than 180 characters. Please edit the Points file!"
              else 

                if attrs['nutshell'][0..176].index(' ')
                  last_space = attrs['nutshell'][0..176].length - 1 - attrs['nutshell'][0..176].reverse.index(' ')
                else 
                  last_space = 0
                end

                if attrs['nutshell'][0..176].index('.')
                  last_period = attrs['nutshell'][0..176].length - 1 - attrs['nutshell'][0..176].reverse.index('.')
                else 
                  last_period = 0
                end 

                last_space_or_period = [last_space || 0, last_period || 0].max

                attrs['text'] = attrs['nutshell'][(last_space_or_period + 1)..-1]
                attrs['nutshell'] = attrs['nutshell'][0..last_space_or_period] + '...'
              end 
            end
            
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
              opinion.include point
            else
              point.update_attributes attrs
              modified[table].push "Updated Point '#{point.nutshell}'"
            end

            point.recache

            if row.has_key? 'id'
              points[row['id']] = point
            end         

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
              opinion.point_inclusions = inclusions
              opinion.save
            end
            modified['opinions'].push "Created Opinion by #{user.name} on '#{proposal.name}'"
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

    tag_whitelist = request.query_parameters.keys()

    exports = [
      {fname: "#{subdomain.name}-opinions.csv",  rows: Exports.opinions(subdomain)},
      {fname: "#{subdomain.name}-points.csv",    rows: Exports.points(subdomain)},
      {fname: "#{subdomain.name}-users.csv",     rows: Exports.users(subdomain, tag_whitelist)},
      {fname: "#{subdomain.name}-proposals.csv", rows: Exports.proposals(subdomain)},
    ]

    zip_path = "#{EXPORT_PATH}#{subdomain.name}.zip"
    Zip::File.open(zip_path, Zip::File::CREATE) do |z|

      exports.each do |ex|
        write_csv(ex[:fname], ex[:rows])

        f = CSV.open(EXPORT_PATH + ex[:fname], 'a')
        z.add(ex[:fname], f.path)
      end

    end 

    send_file zip_path, type: 'application/zip',
      disposition: 'attachment',
      filename: "#{current_subdomain.name}-data.zip"

  end






  def import_argdown
    authorize! 'update subdomain'

    errors = []

    modified = {
      "lists" => [],
      "proposals" => [],
      "points" => [],
      "comments" => []
    }

    file = params["argdown-file"]
    worked = false
    encoding = ''
    ['utf-8', 'windows-1251:utf-8', 'windows-1256:utf-8'].each do |enc|
      encoding = enc
      begin 
        file.tempfile.read :encoding => encoding
        worked = true
      rescue
      end
      break if worked
    end

    def parse_parts(line)
      line = line.strip
      line.force_encoding("utf-8")

      title_start = line.index('[')
      title_end = line.index(']')

      if title_start == nil
        title_start = 0
        title_end = -1
        desc_start = desc_end = -1
      else 
        title_start += 1
        desc_start = title_end + 1
        if line[title_end + 1] == ':'
          desc_start += 1
        end
        desc_end = -1
        title_end -= 1
      end

      meta_starts = -1
      if line[-1] == '}'
        meta_starts = line.index('{')
        desc_end = meta_starts - 1
        if meta_starts < title_end || title_end == -1
          title_end = meta_starts - 1
        end
      end 

      {
        title: line[title_start..title_end].strip,
        desc: desc_start > -1 ? line[desc_start..desc_end].strip: nil,
        meta: meta_starts > -1 ? JSON.parse(line[meta_starts..-1].strip) : {}
      }
    end


    subdomain = current_subdomain
    customization = subdomain.customizations
    active_user = current_user

    current_page = current_list = current_proposal = current_point = nil
    file.tempfile.readlines(:encoding => encoding).each do |line|
      next if line.strip.length == 0

      if line.strip[0] == '{' && line.strip[-1] == '}'
        # parsing an instruction block
        instructions = JSON.parse line.strip
        if instructions['active_user']
          active_user = User.find(instructions['active_user'].to_i)
        end

      elsif line.start_with?('### ')
        # parsing a page (currently used for tabs)
        current_page = line[4..-5].strip
        current_list = current_proposal = current_point = nil

      elsif line[0] == '['
        # parsing a list

        current_proposal = current_point = nil
        list_config = parse_parts(line)

        if list_config[:meta].has_key?("list_key")
          current_list = list_config[:meta]["list_key"]
        else 
          current_list = "list/#{slugify(list_config[:title])}"
        end

        params = {
            "list_title" => list_config[:title],
            "list_description" => list_config[:desc],
            "created_by" => "/user/#{active_user.id}"
          }

        if !subdomain.customizations.has_key?(current_list)
          subdomain.customizations[current_list] = params
          modified['lists'].push "Created list #{subdomain.customizations[current_list]["list_title"]}"
        else 
          subdomain.customizations[current_list].merge!(params)
          modified['lists'].push "Modified list #{subdomain.customizations[current_list]["list_title"]}"
        end

        if list_config[:meta]
          subdomain.customizations[current_list].merge!(list_config[:meta])
        end

        if current_page
          subdomain.customizations["homepage_tabs"] ||= []

          tab_config = subdomain.customizations["homepage_tabs"]
          if !tab_config 
            subdomain
          end

          page_config = nil 
          found = false 

          tab_config.each do |page|
            if page["name"] == current_page
              found = true
              page["lists"] ||= []
              if !page["lists"].index(current_list)
                page["lists"].push(current_list)
                modified['lists'].push "Added list #{subdomain.customizations[current_list][:list_title]} to #{current_page}"
              end
            end
          end

          if !found 
            tab_config.push({"name": current_page, "lists": [current_list]})
            modified['lists'].push "Created page #{current_page}"
            modified['lists'].push "Added list #{subdomain.customizations[current_list][:list_title]} to #{current_page}"
          end
        end 

        subdomain.save

      elsif line.start_with?('* ') && current_list
        # parsing a proposal
        current_point = nil

        title = line[line.index('[')..line.index(']') - 1]
        desc = line[line.index(']') + 1..-1]
        proposal_config = parse_parts(line)

        if proposal_config[:meta].has_key?("slug")
          current_proposal = Proposal.find_by_slug proposal_config[:meta]["slug"]
        elsif proposal_config[:meta].has_key?("id") && Proposal.find_by_id(proposal_config[:meta]["id"])
          current_proposal = Proposal.find proposal_config[:meta]["id"]
        else 
          current_proposal = Proposal.find_by_name proposal_config[:title]
        end

        if proposal_config[:meta].has_key?("user")
          user = User.find proposal_config[:meta]["user"][6..-1]
        else
          user = active_user
        end

        params = {
            'subdomain_id': subdomain.id,
            'user_id': user.id,
            'name': proposal_config[:title],
            'description': proposal_config[:desc],
            'cluster': current_list[5..-1],
            'published': true
          }
        if !current_proposal
          current_proposal = Proposal.new(params)
          modified['proposals'].push "Created Proposal #{current_proposal.name}"

        else
          current_proposal.update_attributes params
          modified['proposals'].push "Modified Proposal #{current_proposal.name}"
        end
        current_proposal.save

        if proposal_config[:meta]
          vals = proposal_config[:meta]
          if vals.has_key?("author_opinion")
            val = vals["author_opinion"].to_f
            opinion = Opinion.get_or_make(current_proposal, user)
            opinion.stance = val
            opinion.published = true
            opinion.save
          end
        end

      elsif current_proposal && (line.start_with?('  +') || line.start_with?('  -'))
        # parsing a pro or con
        is_pro = line[2] == '+'

        point_config = parse_parts(line[3..-1])

        if point_config[:meta].has_key?("id") && Point.find_by_id(point_config[:meta]["id"])
          current_point = Point.find point_config[:meta]["id"]
        else 
          current_point = Point.find_by_nutshell point_config[:title]
        end

        if point_config[:meta].has_key?("user")
          user = User.find point_config[:meta]["user"][6..-1]
        else
          user = active_user
        end
        

        opinion = Opinion.get_or_make(current_proposal, user)

        attrs = {
            'subdomain_id': subdomain.id,
            'proposal_id': current_proposal.id,
            'user_id': user.id,
            'nutshell': point_config[:title],
            'text': point_config[:desc],
            'is_pro': is_pro,
            'published': true
          }
        if !current_point
          current_point = Point.new(attrs)
          modified['points'].push "Created point #{current_point.nutshell}"
        else 
          current_point.update_attributes attrs
          modified['points'].push "Modified point #{current_point.nutshell}"
        end
        current_point.save

        opinion.include current_point

      elsif current_point && line.start_with?('    *')
        # parsing a comment
        comment_config = parse_parts(line[5..-1])

        if comment_config[:meta].has_key?("id") && current_point.comments.find_by_id(comment_config[:meta]["id"])
          comment = current_point.comments.find comment_config[:meta]["id"]
        else 
          comment = current_point.comments.find_by_body comment_config[:title]
        end

        if comment_config[:meta].has_key?("user")
          user = User.find comment_config[:meta]["user"][6..-1]
        else
          user = active_user
        end

        params = {
            'subdomain_id': subdomain.id,
            'user_id': user.id,
            'body': comment_config[:title],
            'point_id': current_point.id,
            'commentable_type': 'Point',
            'commentable_id': current_point.id
          }

        if !comment
          comment = Comment.new(params)
          modified['comments'].push "Created comment #{comment.body}"
        else 
          comment.update_attributes params 
        end
        comment.save

        current_point.comment_count = current_point.comments.count
        current_point.save


      elsif line.strip.start_with?('//') # skip comment
        pp "comment: ", line.strip
      else 
        errors.push "Could not read line '#{line}'"
      end



    end

    if errors.length > 0
      render :json => [{'errors' => errors.uniq}]
    else
      render :json => [modified]
    end

  end

  def export_argdown 
    @active_user = current_user
    @subdomain = current_subdomain    

    @argdown = "///// Forum: #{current_subdomain.name} /////"

    def get_list_for_proposal(proposal)
      "list/#{(proposal.cluster or 'Proposals').strip}"
    end


    if @subdomain.moderation_policy == 1
      moderation_status_check = "(moderation_status=1 OR user_id=#{current_user.id})"
    else 
      moderation_status_check = "(moderation_status IS NULL OR moderation_status=1 OR user_id=#{current_user.id})"
    end

    @proposals_by_list = {}
    @subdomain.proposals.where(moderation_status_check).each do |p|
      l = get_list_for_proposal(p)
      @proposals_by_list[l] ||= []
      @proposals_by_list[l].push p
    end

    @points_by_proposal = {}
    @subdomain.points.where(moderation_status_check).each do |p|
      @points_by_proposal[p.proposal_id] ||= []
      @points_by_proposal[p.proposal_id].push p
    end

    @comments_by_point = {}
    @subdomain.comments.where(moderation_status_check).each do |p|
      @comments_by_point[p.point_id] ||= []
      @comments_by_point[p.point_id].push p
    end




    def ex_page(page)
      if page["name"].length > 0 
        @argdown += "\n\n### #{page["name"].strip} ###\n"
      end
      page["lists"].each do |list|
        ex_list(list)
      end
    end

    def ex_list(list_key)
      list = @subdomain.customizations[list_key]      

      desc = list["list_description"]
      if !params[:exclude_descriptions] && desc && desc.strip.length > 0
        desc = ": #{desc}"
      else 
        desc = ""
      end
      meta = list.clone
      meta["list_key"] = list_key
      ['list_title', 'list_description', 'created_at'].each do |k|
        if meta.has_key?(k)
          meta.delete(k)
        end
      end 
      meta_str = meta.length > 0 || params[:exclude_metadata] ? ' ' + JSON.dump(meta) : ""

      @argdown += "\n[#{list["list_title"].strip}]#{desc}#{meta_str}\n"

      if !params[:exclude_proposals]
        (@proposals_by_list[list_key] || []).each_with_index do |p, idx|
          ex_proposal(p, idx)
        end
      end
    end

    def ex_proposal(proposal, idx)
      if !params[:exclude_descriptions] && proposal.description && proposal.description.strip.length > 0
        desc = ": #{proposal.description.strip.gsub(/\R+/, '<br>')}"
      else 
        desc = ""
      end

      author_opinion = proposal.opinions.find_by_user_id(proposal.user_id)

      meta = {
        "id": proposal.id,
        "user": "/user/#{proposal.user_id}"
      }
      if author_opinion
        meta["author_opinion"] = "#{author_opinion.stance}"
      end
      meta_str =  params[:exclude_metadata] ? '' : JSON.dump(meta)

      if params[:use_indexes]
        char = "#{idx}."
      else
        char = '*'
      end

      @argdown += "\n#{char} [#{proposal.name.strip.gsub(/\R+/, '<br>')}]#{desc} #{meta_str}\n"

      if !params[:exclude_points]
        (@points_by_proposal[proposal.id] || []).each_with_index do |p, idx|
          ex_point(p, idx)
        end
      end
    end

    def ex_point(point, idx)
      if !params[:exclude_descriptions] && point.text && point.text.strip.length > 0
        desc = ": #{point.text.strip.gsub(/\R+/, '<br>')}"
      else 
        desc = ""
      end
      if point.is_pro 
        valence = '+'
      else 
        valence = '-'
      end

      if params[:use_indexes]
        valence = "#{idx}. "
      end

      meta = {
        "id": point.id,
        "user": "/user/#{point.user_id}"
      }
      meta_str = params[:exclude_metadata] ? '' : JSON.dump(meta)

      @argdown += "\n  #{valence} [#{point.nutshell.strip.gsub(/\R+/, '<br>')}]#{desc} #{meta_str}\n"
      
      if !params[:exclude_comments]
        (@comments_by_point[point.id] || []).each do |p|
          ex_comment(p)
        end
      end
    end

    def ex_comment(comment)
      meta = {
        "id": comment.id,
        "user": "/user/#{comment.user_id}"
      }
      meta_str = params[:exclude_metadata] ? '' : JSON.dump(meta)

      @argdown += "\n    * #{comment.body.strip.gsub(/\R+/, '<br>')} #{meta_str}\n"
    end

    pages = @subdomain.customizations["homepage_tabs"]

    if !pages 
      lists = []
      @subdomain.customizations.each do |k,v|
        if k.match( /list\// )
          lists.push k
        end
      end      
      pages = [{"name": '', "lists": lists }]
    end

    pages.each do |page|
      ex_page(page)
    end

    file_path = "#{EXPORT_PATH}#{@subdomain.name}-argdown.txt"
    File.open(file_path, 'w') { |file| file.write(@argdown) }

    send_file file_path, type: 'text/plain',
      disposition: 'attachment',
      filename: "#{current_subdomain.name}-data.txt"


  end

end 



def write_csv(fname, rows)

  CSV.open("#{EXPORT_PATH}#{fname}", "w") do |csv|
    rows.each do |row|
      csv << row 
    end
  end 

end
