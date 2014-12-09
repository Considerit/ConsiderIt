namespace :access do

  # Imports an subdomain, copying all data and handling updating of IDs
  # Make that db schema of source and dest are the same!
  task :control => :environment do

    Proposal.where('publicity > 0').each do |prop|
      roles = '{"editor":["' + prop.user.key + '"],"writer":["*"],"commenter":["*"],"opiner":["*"],"observer":["*"]}'
      prop.roles = roles
      prop.save
    end

    Proposal.where('publicity = 0').each do |prop|
      emails = prop.access_list.gsub(' ', '').split(',')
      observers = []
      emails.each do |email|
        u = User.find_by_email(email)
        if u
          observers.push "\"#{u.key}\""
        else
          observers.push "\"#{email}\""
        end        
      end
      observers = "[#{observers.join(',')}]"
      roles = '{"editor":["' + prop.user.key + '"],"writer":["*"],"commenter":["*"],"opiner":["*"],"observer":' + observers + '}'

      prop.roles = roles
      prop.save
    end

  end

end
