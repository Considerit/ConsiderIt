class ApplicationController < ActionController::Base
  protect_from_forgery
  
  #TODO: move this method?
  def get_bucket(value)
    if value == -1
      return 0
    elsif value == 1
      return 6
    elsif value <= 0.05 && value >= -0.05
      return 3
    elsif value >= 0.5
      return 5
    elsif value <= -0.5
      return 1
    elsif value >= 0.05
      return 4
    elsif value <= -0.05
      return 2
    end   
  end  

  def stance_name(d)
    case d
      when 0
        return "strongly oppose"
      when 1
        return "oppose"
      when 2
        return "moderately oppose"
      when 3
        return "are undecided on"
      when 4
        return "moderately support"
      when 5
        return "support"
      when 6
        return "strongly support"
    end   
  end  
  
end
