#*********************************************
# For the ConsiderIt project.
# Copyright (C) 2010 - 2012 by Travis Kriplean.
# Licensed under the AGPL for non-commercial use.
# See https://github.com/tkriplean/ConsiderIt/ for details.
#*********************************************

module HomeHelper

  def get_users_with_picts(num)
    pics = User.where('avatar_file_name IS NOT NULL')
    pics.sample( [num, pics.count].min )
  end
end
