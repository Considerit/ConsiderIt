class UserMailer < ActionMailer::Base

  def proposal_subscription(user, pnt, from)
    @user = user
    @point = pnt
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] new #{@point.is_pro ? 'pro' : 'con'} point for #{@point.proposal.category} #{@point.proposal.designator}")
  end

  def position_subscription(user, position, from)
    @user = user
    @position = position
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] new review #{@point.proposal.category} for #{@position.proposal.category} #{@position.proposal.designator}")
  end  

  def someone_discussed_your_point(user, pnt, comment, from)
    @user = user
    @point = pnt
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end

  def someone_discussed_your_position(user, position, comment, from)
    @user = user
    @position = position
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] new comment on your review")
  end  

  def someone_commented_on_thread(user, obj, comment, from)
    @user = user
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"

    if obj.commentable_type == 'Point'
      @point = obj
      mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] #{@comment.user.name} also commented on #{@point.user.name}'s #{@point.is_pro ? 'pro' : 'con'} point")
    elsif obj.commentable_type == 'Position'
      @position = obj
      mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] #{@comment.user.name} also commented on #{@position.user.name}'s review")
    end
  end

  def someone_commented_on_an_included_point(user, pnt, comment, from)
    @user = user
    @point = pnt
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end

  def someone_reflected_your_point(user, bullet, comment, from)
    @user = user
    @bullet = bullet
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
        
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] #{@bullet.user.name} summarized your comment")
  end

  def your_reflection_was_responded_to(user, response, bullet, comment, from)
    @user = user
    @bullet = bullet
    @comment = comment
    @response = response
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:from => from, :to => email_with_name, :subject => "[current_tenant.app_title] #{@comment.user.name} responded to your summary")
  end

end