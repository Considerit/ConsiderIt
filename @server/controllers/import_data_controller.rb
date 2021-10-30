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
        required_fields: ['topic|title', 'user'],
        directly_extractable: ['description', 'cluster', 'seo_title', 'seo_description', 'seo_keywords', 'json']
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
            errors.append "#{table} file has some empty entries for the #{rq} field"
          end

          # Find each required relational object
          if config[:required_fields].include? 'user'
            user = nil 
            if row['user']
              user = User.find_by_email(row['user'].downcase)
            end

            if !user
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

            title = row.fetch('title', false) || row.fetch('topic', false)
            list = row.fetch('list', false) || row.fetch('cluster', false)

            next if !title

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
            end

            attrs.update({
              'slug' => slug,
              'user_id' => user.id,
              'name' => title,
              'published' => true,
              'cluster' => list
            })

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

end 


def write_csv(fname, rows)

  CSV.open("#{EXPORT_PATH}#{fname}", "w") do |csv|
    rows.each do |row|
      csv << row 
    end
  end 

end
