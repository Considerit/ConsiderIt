module OptionsHelper
  
  def stance_fractions( option )
    
    distribution = Array.new(7,0)
    option.positions.select('count(*) cnt, stance_bucket').group(:stance_bucket).each do |row|
      distribution[row.stance_bucket.to_i] = row.cnt.to_i
    end      
    total = distribution.inject(:+).to_f    
    distribution.collect! { |stance_count| sprintf "%.1f", (100 * stance_count / total) }
    return '[' + distribution.join(',') + ']'
  end  
  
end
