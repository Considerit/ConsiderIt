module Moderatable
  extend ActiveSupport::Concern

  included do 
    has_one :moderation, :as => :moderatable, 
            :class_name => 'Moderation', :dependent => :destroy    
  end

  def okay_to_email_notification
    mod_setting = self.subdomain.moderation_policy

    [nil, 0, 3].include?(mod_setting) || \
      (self.moderation && self.moderation.status == 1)
  end

  def moderation_enabled
    mod_setting = self.subdomain.moderation_policy
    !!mod_setting
  end

  def notify_moderator
    Notifier.create_notification 'content_to_moderate', self, 
                                 :digest_object => self.subdomain
  end

  def redo_moderation
    if self.moderation
      self.moderation.updated_since_last_evaluation = true
      self.moderation.save
    end
  end

end

