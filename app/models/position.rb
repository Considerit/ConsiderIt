class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :proposal  
  has_many :inclusions
  has_many :points
  has_many :point_listings
  has_many :comments, :as => :commentable, :dependent => :destroy

  has_paper_trail  
  is_commentable
  
  #acts_as_paranoid_versioned
  acts_as_tenant(:account)
  
  #default_scope where( :published => true )
  scope :published, where( :published => true )

  def notify_parties(current_tenant, options)
    message_sent_to = {}
    begin
      #email anyone who subscribes to reviews for the proposal
      proposal.positions.published.where(:notification_perspective_subscriber => true).each do |pos|
        position_taker = pos.user
        if position_taker.id != user_id && !message_sent_to.has_key?(position_taker.id)
          if position_taker.email && position_taker.email.length > 0
            UserMailer.delay.position_subscription(position_taker, self, options)#.deliver
          end
          message_sent_to[position_taker.id] = [position_taker.name, 'subscribed to position']
        end
      end
    rescue
    end
    return message_sent_to
  end
    
  def stance_name
    case stance_bucket
      when 0
        return "strong oppose"
      when 1
        return "oppose"
      when 2
        return "weak oppose"
      when 3
        return "undecided"
      when 4
        return "weak support"
      when 5
        return "support"
      when 6
        return "strong support"
    end
  end    

  def stance_name_adverb
    case stance_bucket
      when 0
        return "strongly oppose"
      when 1
        return "oppose"
      when 2
        return "weakly oppose"
      when 3
        return "are undecided"
      when 4
        return "weakly support"
      when 5
        return "support"
      when 6
        return "strongly support"
    end
  end    


  def stance_long
    case stance_bucket
      when 0
        return "This paper definitely should not be accepted"
      when 1
        return "This paper is not CHI material"
      when 2
        return "I'm borderline, but leaning against its acceptance"
      when 3
        return "I would not argue for or against this paper"
      when 4
        return "I'm borderline, but leaning for its acceptance"
      when 5
        return "This paper is solid CHI material"
      when 6
        return "This paper definitely should be accepted"
    end
  end    

end



