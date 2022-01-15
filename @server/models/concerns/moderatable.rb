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

    # auto fail content posted by shadow banned account
    if !self.moderation 
      bans = self.subdomain.customization_json['shadow_bans'] || []
      if bans.include? "/user/#{self.user_id}" 
        m = Moderation.create :moderatable_type => self.class.name, :moderatable_id => self.id, :subdomain_id => current_subdomain.id
        m.status = 0
        m.user_id = current_user.id
        m.updated_since_last_evaluation = false
        m.save
        self.moderation_status = 0 
        self.save
      end
    end

    Notifier.notify_parties 'content_to_moderate', self, self.subdomain
  end

  def redo_moderation
    if self.moderation
      self.moderation.updated_since_last_evaluation = true
      self.moderation.save
    end
  end

end

