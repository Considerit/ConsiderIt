#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

module HomeHelper

  def get_users(num)
    users = []
    searched = []
    total = User.count
    i = 0
    #TODO: make this work not just for MYSQL
    while users.length < num && searched.length < total * 0.9
      ids = User.select(:id).order('RAND()').limit(num * 1.5).offset(i)
      to_look_at = ids - searched
      searched += to_look_at
      users += User.find(to_look_at.map {|x| x.id}.compact).reject{|u| u.avatar_file_name.nil? } 
      i += 1
    end

    users[0..num]
  end

end
