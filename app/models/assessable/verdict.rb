class Assessable::Verdict < ActiveRecord::Base

  has_many :assessments
  has_many :claims

  acts_as_tenant :account

  has_attached_file :icon, 
    :styles => { 
      :square => "25x25#"
    },
    :processors => [:thumbnail, :paperclip_optimizer]

  def formatVerdict
    if id == -1
      'No claims'
    else
      short_name
    end
  end

end