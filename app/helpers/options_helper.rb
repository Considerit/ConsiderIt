module OptionsHelper
  
  #TODO: review these methods, rename better
  def total_count( initiative, is_pro )
    return 0
    #key = "init-#{initiative.id}".intern

    #if ( is_pro )
    #  return PointList.new(session[key][:pro_list]).pagination()
    #else
    #  return PointList.new(session[key][:con_list]).pagination()
    #end
  end  
  
  def total( initiative, is_pro)
    return 0
    #key = "init-#{initiative.id}".intern
    #if ( is_pro )
    #  return PointList.new(session[key][:pro_list]).total_count()
    #else
    #  return PointList.new(session[key][:con_list]).total_count()
    #end    
  end
  
  def complete_list_showing( initiative, is_pro )
    return false
#    key = "init-#{initiative.id}".intern
#    if ( is_pro )
#      return PointList.new(session[key][:pro_list]).complete_list_showing()
#    else
#      return PointList.new(session[key][:con_list]).complete_list_showing()
#    end    
  end  
  
  
  def stance_counts( option )
    return '[' + discrete_stances().collect! { |bucket| stances_with_value(option, bucket).length }.join(',') + ']'
  end
  
  def stance_fractions( option )
    
    arr = discrete_stances().collect { |bucket| stances_with_value(option, bucket).length }
    total = Float(arr.inject( nil ) { |sum,x| sum ? sum+x : x })
    arr.collect! { |stance_count| sprintf "%.1f", (100 * stance_count / total) }
    return '[' + arr.join(',') + ']'
  end  
  
  def discrete_stances( )
    return (0..6).step(1)
  end
  
  def stances_with_value( option, value )
    return Position.all( :conditions => { :option_id => @option.id, :stance_bucket => value })
  end  
  
  
end
