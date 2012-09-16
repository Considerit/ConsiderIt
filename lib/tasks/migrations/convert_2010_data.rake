#require 'pg'
require 'pp'

namespace :data do
  desc ""  
  task :convert => :environment do  
    save = true
    conn = PG.connect( dbname: 'considerit-production', user: 'postgres', password: 'postgres' ) 

    puts 'USERS'

    # extract users
    u2011 = {}
    User.all.each do |u|
      u2011[u.email] = u
    end

    # stores a mapping from 2010 user id => 2011 user id
    users = {}

    conn.exec( "SELECT * from users" ) do |result| 

      result.each do |row|
        if u2011.has_key?(row['email'])
          # if this user exists in 2011, then use the 2011 user
          user = u2011[row['email']]
          user.sign_in_count += row['login_count'].to_i
          user.created_at = row['created_at']
        else
          
          if !row['facebook_id'] || row['facebook_id'].length == 0
            row['email'] = row['email'] + '.ghost'
          end
          user = User.new({
            :name => row['name'],
            :email => row['email'],
            :account_id => 1,
            :facebook_uid => row['facebook_id'],
            :created_at => row['created_at'],
            :sign_in_count => row['login_count'].to_i,
            :current_sign_in_at => row['current_login_at'],
            :last_sign_in_at => row['last_login_at'],
            :current_sign_in_ip => row['current_login_ip'],
            :last_sign_in_ip => row['last_login_ip'],
            :avatar_file_name => row['avatar_file_name'],
            :avatar_content_type => row['avatar_content_type'],
            :avatar_file_size => row['avatar_file_size'],
            :avatar_updated_at => row['avatar_updated_at'],
            :avatar_remote_url => row['avatar_remote_url'],
            :registration_complete => 1
          })
          user.confirmed_at = user.created_at
        end
        user.account_id = 1
        user.save if save

        users[row['id']] = user
      end
    end

    puts 'PROPOSALS'
    # extract proposals
    proposals = {}
    conn.exec( "SELECT * from initiatives" ) do |result| 
      
      result.each do |row|
        proposal = Proposal.new({
          :designator => row['number'],
          :user_id => 1,
          :category => row['designation'],
          :created_at => row['created_at'],
          :updated_at => row['updated_at'],
          :image => row['img'],
          :short_name => row['short_name'].capitalize,
          :name => row['name'].capitalize,
          :url => row['url'],
          :description => row['short_desc'],
          :long_description => row['full_desc'],
          :domain_short => 'WA State',
          :domain => 'State of Washington',
          :account_id => 1,
          :session_id => 'none'
        })
        proposal.add_long_id
        proposals[row['id']] = proposal

        proposal.save if save
      end
    end

    puts 'POSITIONS'

    # extract positions
    positions = {}
    conn.exec( "SELECT * from stances" ) do |result| 
      result.each do |row|
        position = Position.new({
          :created_at => row['created_at'],
          :updated_at => row['updated_at'],
          :proposal_id => proposals[row['initiative_id']].id,
          :user_id => users[row['user_id']].id,
          :stance => row['position'].to_f,
          :stance_bucket => Position.get_bucket(row['position'].to_f),
          :account_id => 1,
          :published => row['active'].to_i
        })

        positions[row['id']] = position

        position.save if save
      end
    end

    puts 'POINTS'

    # extract points
    points = {}
    conn.exec( "SELECT * from points" ) do |result| 
      result.each do |row|
        point = Point.new({
          :created_at => row['created_at'],
          :updated_at => row['updated_at'],
          :proposal_id => proposals[row['initiative_id']].id,
          :user_id => users[row['user_id']].id,
          :text => row['text'],
          :nutshell => row['nutshell'],
          :account_id => 1,
          :published => row['status'].to_i,
          :is_pro => row['position'].to_i
        })
        
        if save && users[row['user_id']].positions.where(:proposal_id => proposals[row['initiative_id']].id).count > 0
          point.position_id = users[row['user_id']].positions.where(:proposal_id => proposals[row['initiative_id']].id).published.first.id if save
        end
        points[row['id']] = point

        point.save if save
      end
    end

    puts 'INCLUSIONS'

    # extract inclusions
    inclusions = {}
    conn.exec( "SELECT * from inclusions" ) do |result| 
      result.each do |row|
        if users[row['user_id']].positions.where(:proposal_id => proposals[row['initiative_id']].id).published.count > 0
          inclusion = Inclusion.new({
            :created_at => row['created_at'],
            :updated_at => row['created_at'],
            :proposal_id => proposals[row['initiative_id']].id,
            :user_id => users[row['user_id']].id,
            :point_id => points[row['point_id']].id,
            :account_id => 1
          })

          inclusion.position_id = users[row['user_id']].positions.where(:proposal_id => proposals[row['initiative_id']].id).published.first.id if save

          inclusions[row['id']] = inclusion

          inclusion.save if save
        end
      end
    end


    puts 'POINT LISTINGS'

    # extract point listings
    listings = {}
    conn.exec( "SELECT * from point_listings where user_id is not null" ) do |result| 
      result.each do |row|
        if users[row['user_id']].positions.where(:proposal_id => proposals[row['initiative_id']].id).published.count > 0

          listing = PointListing.new({
            :created_at => row['created_at'],
            :updated_at => row['created_at'],
            :proposal_id => proposals[row['initiative_id']].id,
            :user_id => users[row['user_id']].id,
            :point_id => points[row['point_id']].id,
            :account_id => 1
          })

          listing.position_id = users[row['user_id']].positions.where(:proposal_id => proposals[row['initiative_id']].id).published.first.id if save

          listings[row['id']] = listing

          listing.save if save
        end
      end
    end

    puts 'COMMENTS'

    # extract comments
    comments = {}
    conn.exec( "SELECT * from comments where point_id is not null" ) do |result| 
      result.each do |row|
        comment = Comment.new({
          :created_at => row['created_at'],
          :updated_at => row['updated_at'],

          :user_id => users[row['user_id']].id,

          :body => row['body'],

          :commentable_id => points[row['point_id']].id,
          :commentable_type => 'Point',
          :account_id => 1
        })

        comments[row['id']] = comment

        comment.save if save
      end
    end
  end

  task :reimage => :environment do  
    User.where('id > 449 AND avatar_remote_url IS NOT NULL').each do |u|
      puts u.avatar_remote_url
      u.download_remote_image
      u.save
    end

    require 'net/scp'
    conn = PG.connect( dbname: 'considerit-production', user: 'postgres', password: 'postgres' ) 
    user = ''
    passwrd = ''
    host = ''
    local = '/Users/travis/Desktop/avatars/'    
    Net::SCP.start(host, user, :password => passwrd) do |scp|
      User.where('id > 449 AND avatar_remote_url IS NULL AND avatar_file_name is NOT NULL').each do |u|
        pp u.email
        em = u.email[0..-7]
        conn.exec( "SELECT * from users where lower(email)=lower('#{em}')" ) do |result| 
          user = result[0]
          puts sprintf("%i\t%s\t%s", u.id, u.email, u.avatar_file_name)
          loc = '/projects/engage2/lvg/code/considerit/public/images/avatars/uploaded/' + user['id'] + '/original_' + u.avatar_file_name
          # download a file to an in-memory buffer
          fname = local + u.avatar_file_name
          scp.download!(loc, fname)          
          io = open(fname)
          u.avatar = io
          u.save
        end
      end
    end
  end
end