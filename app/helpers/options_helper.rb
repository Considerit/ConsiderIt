module OptionsHelper
  
  
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
