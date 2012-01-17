module ProposalHelper
  
  def stance_fractions( proposal )
    
    distribution = Array.new(7,0)
    proposal.positions.select('COUNT(*) AS cnt, stance_bucket').group(:stance_bucket).each do |row|
      distribution[row.stance_bucket.to_i] = row.cnt.to_i
    end      
    total = distribution.inject(:+).to_f    
    distribution.collect! { |stance_count| sprintf "%.1f", (100 * stance_count / total) }
    return '[' + distribution.join(',') + ']'
  end

  # def number_responses( comment )
  #   comments = 0
  #   comment.children.each do |child|
  #     comments += 1 + number_responses(child)
  #   end
  #   return comments
  # end
  
  
end
