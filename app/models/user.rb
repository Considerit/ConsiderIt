class User < ActiveRecord::Base
  has_many :points
  has_many :inclusions
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
  devise :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  def self.find_for_facebook_oauth(access_token, signed_in_resource=nil)
    data = access_token['extra']['user_hash']
    if user = User.find_by_email(data["email"])
      user
    else # Create a user with a stub password. 
      User.create!(:email => data["email"], :password => Devise.friendly_token[0,20]) 
    end
  end
  
  
  #TODO: should these methods be here?
  def supporting_points ( option, limit = nil, page = nil )
    return get_points( option, true, limit, page)
  end
  
  def opposing_points ( option, limit = nil, page = nil )
    return get_points( option, false, limit, page)
  end  

protected

  def get_points( option, is_pro, limit, page )
    #TODO: obey pagination
    if limit
      #jdgs = Judgement.paginate :page => page, :per_page => limit, :conditions => {:user_id => self.id, :judgement => 1, :initiative_id => initiative.id, :active => 1}
      #return jdgs #.collect { |jdg| jdg.point }.select { |pnt| pnt.position == position}
      return self.inclusions.where(:option_id => option.id).collect { |inc| inc.point }.select { |pnt| pnt.is_pro == is_pro}
      
    else
      return self.inclusions.where(:option_id => option.id).collect { |inc| inc.point }.select { |pnt| pnt.is_pro == is_pro}
    end
    
  end
  
      
end
