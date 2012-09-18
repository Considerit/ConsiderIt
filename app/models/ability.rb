class Ability
  include CanCan::Ability

  def initialize(user, session_id=nil, params=nil)
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

    user_facing_models = [User, Point, Position, Inclusion, Proposal]
        


    if user.has_role? :superadmin
      can :manage, :all
    end

    if user.has_role? :moderator
      can [:index, :create], Moderatable::Moderation
    end

    #Rails_admin
    if user.is_admin?
      can :access, :rails_admin       # only allow admin users to access Rails Admin
      can :dashboard                  # allow access to dashboard
      can :manage, user_facing_models
      can [:index, :create, :update, :destroy, :read], :all
    else
      #Proposal
      can :read, Proposal#, :published => 1

      can [:read, :create, :update], Proposal do |prop|
        (!user.id.nil? && user.id == prop.user_id) || (session_id == prop.session_id) || (params.has_key?(:admin_id) && params[:admin_id] == prop.admin_id)
      end

      can [:destroy], Proposal do |prop|
        ((!user.id.nil? && user.id == prop.user_id) || (session_id == prop.session_id) || (params.has_key?(:admin_id) && params[:admin_id] == prop.admin_id)) && \
          (prop.positions.published.count == 0 || (prop.positions.published.count == 1 && prop.positions.published.first.user_id == user.id))
      end

      #Position
      can [:create, :update, :destroy], Position, :user_id => user.id

      #Point
      can :read, Point, :published => true, :moderation_status => 1
      can :create, Point
      can [:read, :update], Point do |pnt|
        (!pnt.published && user.id.nil? && pnt.user_id.nil?) || (user.id = pnt.user_id)
      end 
      can :destroy, Point do |pnt|
        ((user.id.nil? && pnt.user_id.nil?) || (user.id = pnt.user_id)) && pnt.inclusions.count < 2
      end

      #Inclusion
      can :create, Inclusion
      can :destroy, Inclusion, :user_id => user.id

      #Comment
      if !user.id.nil?
        can :create, Commentable::Comment
      end
    end
  end
end
