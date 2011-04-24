module OptionsHelper
  
  def stance_fractions( option )
    
    arr = discrete_stances().collect { |bucket| option.positions.where( :stance_bucket => bucket).count }
    total = Float(arr.inject( nil ) { |sum,x| sum ? sum+x : x })
    arr.collect! { |stance_count| sprintf "%.1f", (100 * stance_count / total) }
    return '[' + arr.join(',') + ']'
  end  
  
  def discrete_stances( )
    return (0..6).step(1)
  end
  
end
