class Ability
  include CanCan::Ability

  def initialize(user, current_subdomain=nil, session_id=nil, session = nil, params=nil)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

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
      can [:index, :create, :update], Assessable::Assessment
      can [:index, :create, :update], Assessable::Claim
      can [:index, :create, :update], Assessable::Request      
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
        (user.registered && user.id == proposal.user_id) || (params.has_key?(:admin_id) && params[:admin_id] == proposal.admin_id)
      end

      can [:destroy], Proposal do |proposal|
        ((user.registered && user.id == proposal.user_id) || (params.has_key?(:admin_id) && params[:admin_id] == proposal.admin_id)) && \
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
        pnt.proposal.active || Rails.env == 'development'
      end
      can :update, Point do |pnt|
        (!pnt.published && pnt.user_id.nil?) || (user.id == pnt.user_id)
      end 
      can :destroy, Point do |pnt|
        ((!pnt.published && pnt.user_id.nil?) || (user.id == pnt.user_id)) && pnt.inclusions.count < 2
      end

      #Inclusion
      can :create, Inclusion
      can :destroy, Inclusion do |inc|
        inc.nil? || inc.opinion.nil? || !inc.opinion.published || inc.opinion.user_id == inc.user_id
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
