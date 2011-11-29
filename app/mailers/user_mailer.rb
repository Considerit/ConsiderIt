class UserMailer < ActionMailer::Base
  default :from => APP_CONFIG['default_from_email'] 

  def option_subscription(user, pnt)
    @user = user
    @point = pnt
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:to => email_with_name, :subject => "[#{APP_CONFIG['email_head']}] new #{@point.is_pro ? 'pro' : 'con'} point for #{@point.option.category} #{@point.option.designator}")
  end

  def someone_discussed_your_point(user, pnt, comment)
    @user = user
    @point = pnt
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:to => email_with_name, :subject => "[#{APP_CONFIG['email_head']}] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end

  def someone_commented_on_thread(user, pnt, comment)
    @user = user
    @point = pnt
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:to => email_with_name, :subject => "[#{APP_CONFIG['email_head']}] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end

  def someone_commented_on_an_included_point(user, pnt, comment)
    @user = user
    @point = pnt
    @comment = comment
    email_with_name = "#{@user.name} <#{@user.email}>"
    mail(:to => email_with_name, :subject => "[#{APP_CONFIG['email_head']}] new comment on a #{@point.is_pro ? 'pro' : 'con'} point you wrote")
  end  

end