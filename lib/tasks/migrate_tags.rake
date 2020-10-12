

task :migrate_tags => :environment do 

  editable = {}
  noneditable = {}

  User.where(:registered => true).where("tags is not NULL").each do |u|
    tags = JSON.load(u.tags)
    tags.each do |k,v|

      if k.index '.editable'
        editable[k] = 1
      else 
        noneditable[k] = 1
      end

    end

  end

  pp editable
  pp '         \n\n\n'
  pp noneditable


end