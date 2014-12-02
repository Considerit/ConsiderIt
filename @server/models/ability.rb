class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new # guest user (not logged in)

    user_facing_models = [User, Point, Opinion, Inclusion, Proposal]
        

    if user.has_role? :superadmin
      can :manage, :all
    end

    if user.has_role? :moderator
      can [:index, :update], Moderation
    end
 
    if user.has_role? :manager
      can [:create], Proposal
    end

    if user.has_role? :evaluator
      can [:index, :create, :update], Assessment
    end

    if user.has_role? :developer
      can [:index, :create, :update, :show], ClientError
    end

    if user.registered
      can :create, Assessable::Request do |req|
        assessment = req.assessment
        assessment.requests.where(:user_id => req.user_id).count < 2
      end
      can :create, Subdomain
    end


    if user.is_admin?
      can :manage, user_facing_models
      can [:index, :create, :update, :destroy, :read], :all
    else
      #Proposal
      can :read, Proposal do |proposal|
        proposal.publicity != 0 || (user.registered && proposal.access_list.downcase.gsub(' ', '').split(',').include?(user.email) )
      end

      can :create, Proposal do |proposal|
        user.has_role?(:manager)
      end

      can [:read, :update], Proposal do |proposal|
        (user.registered && user.id == proposal.user_id)
      end

      can [:destroy], Proposal do |proposal|
        (user.registered && user.id == proposal.user_id) && \
          (proposal.opinions.published.count == 0 || (proposal.opinions.published.count == 1 && proposal.opinions.published.first.user_id == user.id))
      end

      #Opinion
      can [:read], Opinion do |opinion|
        proposal = opinion.proposal
        #TODO: can we just say "authorize :read, proposal"?
        user_has_access_to_proposal = proposal.publicity != 0 || (user.registered && proposal.access_list.downcase.gsub(' ', '').split(',').include?(user.email) )
        user_has_access_to_proposal
      end

      can [:update], Opinion do |opinion|
        proposal = opinion.proposal
        user_has_access_to_proposal = proposal.publicity != 0 || (user.registered && proposal.access_list.downcase.gsub(' ', '').split(',').include?(user.email) )
        (user.id == opinion.user_id) && user_has_access_to_proposal

        #TODO: get this to work! Need to make sure only the original opinion creator can update the opinion
        #(!opinion.published && user.id.nil? && opinion.user_id.nil?) || (user.id == opinion.user_id)
      end

      #Point
      can :read, Point do |pnt|
        (pnt.published && (pnt.moderation_status.nil? || pnt.moderation_status != 0)) || (!pnt.published && pnt.user_id.nil?) || (user.id == pnt.user_id)
      end
      can :create, Point do |pnt|
        pnt.proposal.active
      end
      can :update, Point do |pnt|
        (!pnt.published && pnt.user_id.nil?) || (user.id == pnt.user_id)
      end 
      can :destroy, Point do |pnt|
        ((!pnt.published && pnt.user_id.nil?) || (user.id == pnt.user_id)) && pnt.inclusions.count < 2
      end

      #Comment
      if user.registered
        can :create, Comment
        can :update, Comment, :user_id => user.id
        can :destroy, Comment, :user_id => user.id
      end

      can :create, ClientError

      
    end
  end
end
