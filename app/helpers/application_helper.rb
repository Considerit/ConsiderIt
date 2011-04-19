module ApplicationHelper
  
  def get_initiatives
    return Option.all(:order => "id")
  end

  def has_stance(user, initiative)
    return false
    
    if user.nil? || initiative.nil?
      return 'unfinished'
    end
    
    stance = Stance.last( :conditions => { :user_id => user.id, :initiative_id => initiative.id, :active => 1})
    if stance.nil?
      return 'unfinished'
    end
    
    if stance.bucket == 3
      return 'finished neutral'
    elsif stance.bucket < 3
      return 'finished con'
    else
      return 'finished pro'
    end
    
  end
  
end
