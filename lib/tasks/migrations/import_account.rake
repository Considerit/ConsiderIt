source_host = "localhost"
source_user = 'root'
source_database = "chalkboardit_production"
source_password = "root"
dest_account_identifier = 2026

# NOTE: This only works if the source and dest databases are hosted in same place
# NOTE: This does not import user pictures
namespace :import do
  desc "Based on existing data, initialize the activities table"

  # Imports an account, copying all data and handling updating of IDs
  # Make that db schema of source and dest are the same!
  task :initialize_from_data => :environment do
    to_update = [ 
      ['accounts', {
        :max_id => Account.last.id + 1000,
        :fks => [
          ['proposals', 'account_id'],
          ['points', 'account_id'],
          ['opinions', 'account_id'],
          ['comments', 'account_id'],
          ['assessments', 'account_id'],
          ['claims', 'account_id'],
          ['follows', 'account_id'],
          ['inclusions', 'account_id'],
          ['moderations', 'account_id'],
          ['point_listings', 'account_id'],
          ['requests', 'account_id'],
          ['users', 'account_id']
        ]
      }],
      ['users', {
        :max_id => User.last.id + 1000,
        :fks => [
          ['proposals', 'user_id'],
          ['points', 'user_id'],
          ['opinions', 'user_id'],
          ['comments', 'user_id'],
          ['assessments', 'user_id'],
          ['follows', 'user_id'],
          ['inclusions', 'user_id'],
          ['moderations', 'user_id'],
          ['point_listings', 'user_id'],
          ['requests', 'user_id'],
          ['claims', 'creator'],
          ['claims', 'approver']
        ]
      }],
      ['proposals', {
        :max_id => Proposal.last.id + 1000,
        :fks => [
          ['points', 'proposal_id'],
          ['opinions', 'proposal_id'],
          ['inclusions', 'proposal_id'],
          ['point_listings', 'proposal_id'],
        ]
      }],      
      ['points', {
        :max_id => Point.last.id + 1000,
        :fks => [
          ['comments', ['commentable_id', "commentable_type='Point'"]],
          ['assessments', ['assessable_id', "assessable_type='Point'"]],
          ['follows', ['followable_id', "followable_type='Point'"]],
          ['inclusions', 'point_id'],
          ['moderations', ['moderatable_id', "moderatable_type='Point'"]],
          ['point_listings', 'point_id']
        ]
      }],
      ['opinions', {
        :max_id => Opinion.last.id + 1000,
        :fks => [
          ['points', 'opinion_id'],
          ['comments', ['commentable_id', "commentable_type='Opinion'"]],
          ['follows', ['followable_id', "followable_type='Opinion'"]],
          ['inclusions', 'opinion_id'],
          ['point_listings', 'opinion_id']
        ]
      }],
      ['comments', {
        :max_id => Comment.last.id + 1000,
        :fks => [
          ['follows', ['followable_id', "followable_type='Comment'"]],
          ['moderations', ['moderatable_id', "moderatable_type='Comment'"]],
        ]
      }],
      ['assessments', {
        :max_id => Assessable::Assessment.last.id + 1000,
        :fks => [
          ['requests', 'assessment_id'],
          ['claims', 'assessment_id']          
        ]
      }],
      ['claims', {
        :max_id => Assessable::Claim.last.id + 1000,
        :fks => []
      }],
      ['requests', {
        :max_id => Assessable::Request.last.id + 1000,
        :fks => []
      }],
      ['follows', {
        :max_id => Follow.last.id + 1000,
        :fks => []
      }],      
      ['inclusions', {
        :max_id => Inclusion.last.id + 1000,
        :fks => []
      }],      
      ['verdicts', {
        :max_id => Assessable::Verdict.last.id + 1000,
        :fks => []
      }],          
      ['moderations', {
        :max_id => Moderation.last.id + 1000,
        :fks => []
      }],
      ['point_listings', {
        :max_id => PointListing.last.id + 1000,
        :fks => []
      }],
      ['page_views', {
        :max_id => PageViews.last.id + 1000,
        :fks => []
      }]
    ]



    target_db_has_records = false
    if target_db_has_records
      # first, we'll update record IDs in source database by a constant # equal to the max ID of destination database to eliminate conflicts
      source_db = ActiveRecord::Base.establish_connection(
        :adapter  => "mysql2",
        :host     => source_host,
        :username => source_user,
        :password => source_password,
        :database => source_database
      )

      to_update.each do |model_with_assoc|
        table_name, data = model_with_assoc

        pp table_name
        min_id = source_db.connection.execute( "SELECT MIN(id) FROM #{table_name}").first[0]
        pp min_id

        max_id = data[:max_id]
        next if min_id.nil? || min_id > max_id

        qry = "UPDATE #{table_name} SET id=id+#{max_id}"
        pp qry
        source_db.connection.execute qry
        dest_account_identifier += max_id if table_name == 'accounts'

        data[:fks].each do |relation|
          ftable = relation[0]
          key = relation[1]
          if key.kind_of?(Array)
            where = "#{key[1]} AND #{key[0]} IS NOT NULL"
            key = key[0]
          else
            where = "#{key} IS NOT NULL"
          end
          qry = "UPDATE #{ftable} SET #{key}=#{key}+#{max_id} WHERE #{where}"
          pp qry
          source_db.connection.execute qry
        end
      end
    else
      dest_account_identifier = 1
    end

    base_db = ActiveRecord::Base.establish_connection :development

    # insert all the data into the destination database
    to_update.each do |model_with_assoc|
      table_name, data = model_with_assoc
      col_qry = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '#{table_name}' AND TABLE_SCHEMA='#{source_database}'"    
      cols = base_db.connection.execute(col_qry).map {|r| r}
      qry = "INSERT INTO #{table_name} (#{cols.join(',')}) SELECT #{cols.join(',')} FROM #{source_database}.#{table_name} WHERE #{table_name=='accounts' ? '' : 'account_'}id=#{dest_account_identifier} ORDER BY id"
      pp qry
      base_db.connection.execute qry
    end






  end

end