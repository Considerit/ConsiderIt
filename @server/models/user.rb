require 'open-uri'
require 'onelogin/ruby-saml'

class User < ActiveRecord::Base
  has_secure_password validations: false
  alias_attribute :password_digest, :encrypted_password

  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :inclusions, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :proposals
  has_many :notifications, :dependent => :destroy

  attr_accessor :avatar_url, :downloaded

  before_validation :download_remote_image, :if => :avatar_url_provided?
  before_save do 
    self.email = self.email.downcase if self.email

    self.name = sanitize_helper self.name if self.name   
    self.bio = sanitize_helper self.bio if self.bio
  end

  #validates_presence_of :avatar_remote_url, :if => :avatar_url_provided?, :message => 'is invalid or inaccessible'
  after_create :add_token

  has_attached_file :avatar, 
      :styles => { 
        :large => "250x250#",
        :small => "50x50#"
      },
      :processors => [:thumbnail, :compression]

  process_in_background :avatar

  after_post_process do 
    if self.avatar.queued_for_write[:small]

      img_data = self.avatar.queued_for_write[:small].read

      self.avatar.queued_for_write[:small].rewind
      data = Base64.encode64(img_data)
      b64_thumbnail = "data:image/jpeg;base64,#{data.gsub(/\n/,' ')}"

      begin        
        qry = "UPDATE users SET b64_thumbnail='#{b64_thumbnail}' WHERE id=#{self.id}"
        ActiveRecord::Base.connection.execute(qry)
      rescue => e
        raise "Could not store image for user #{self.id}, it is too large!"
      end

    end
  end

  validates_attachment_content_type :avatar, :content_type => %w(image/jpeg image/jpg image/png image/gif)


  # This will output the data for this user _as if this user is currently logged in_
  # So make sure to only send this data to the client if the client is authorized. 
  def current_user_hash(form_authenticity_token)
    data = {
      id: id, #leave the id in for now for backwards compatability with Dash
      key: '/current_user',
      user: "/user/#{id}",
      logged_in: registered,
      email: email,
      password: nil,
      csrf: form_authenticity_token,
      avatar_remote_url: avatar_remote_url,
      url: url,
      name: name,
      reset_password_token: nil,
      b64_thumbnail: b64_thumbnail,
      tags: Oj.load(tags || '{}'),
      is_super_admin: self.super_admin,
      is_admin: is_admin?,
      is_moderator: permit('moderate content', nil) > 0,
      is_evaluator: permit('factcheck content', nil) > 0,
      trying_to: nil,
      subscriptions: subscription_settings(current_subdomain),
      notifications: notifications.order('created_at desc'),
      verified: verified,
      needs_to_complete_profile: self.registered && (self.complete_profile || !self.name),
                                #happens for users that were created via email invitation
      needs_to_verify: ['bitcoin', 'bitcoinclassic'].include?(current_subdomain.name) && \
                               self.registered && !self.verified

    }

    data
    
  end

  # Gets all of the users active for this subdomain
  def self.all_for_subdomain
    fields = "CONCAT('\/user\/',id) as 'key',users.name,users.avatar_file_name,users.tags"
    if current_user.is_admin?
      fields += ",email"
    end
    if current_subdomain.name == 'homepage'
      users = ActiveRecord::Base.connection.exec_query( "SELECT #{fields} FROM users WHERE registered=1")
    else 
      users = ActiveRecord::Base.connection.exec_query( "SELECT #{fields} FROM users WHERE registered=1 AND active_in like '%\"#{current_subdomain.id}\"%'")
    end 
    # if current_user.is_admin?
    users.each{|u| u['tags']=Oj.load(u['tags']||'{}')}      
    # end

    {key: '/users', users: users.as_json}
  end

  # Note: This is barely used in practice, because most users are
  # generated by the all_for_subdomain() method above.
  def as_json(options={})
    result = { 'key' => "/user/#{id}",
               'name' => name,
               'avatar_file_name' => avatar_file_name,
               'tags' => Oj.load(tags || '{}')  }
                  # TODO: filter private tags
    if current_user.is_admin?
      result['email'] = email
    end
    result
  end

  def is_admin?(subdomain = nil)
    subdomain ||= current_subdomain
    has_any_role? [:admin, :superadmin], subdomain
  end

  def has_role?(role, subdomain = nil)
    role = role.to_s

    if role == 'superadmin'
      return self.super_admin
    else
      subdomain ||= current_subdomain
      roles = subdomain.roles ? Oj.load(subdomain.roles) : {}
      return roles.key?(role) && roles[role] && roles[role].include?("/user/#{id}")
    end
  end

  def has_any_role?(roles, subdomain = nil)
    subdomain ||= current_subdomain
    for role in roles
      return true if has_role?(role, subdomain)
    end
    return false
  end

  def logged_in?
    # Logged-in now means that the current user account is registered
    self.registered
  end

  def add_to_active_in(subdomain=nil)
    subdomain ||= current_subdomain
    
    active_subdomains = Oj.load(self.active_in || "[]")

    if !active_subdomains.include?("#{subdomain.id}")
      active_subdomains.push "#{subdomain.id}"
      self.active_in = JSON.dump active_subdomains
      self.save
    end

  end

  def emails_received
    Oj.load(self.emails || "{}")
  end

  def sent_email_about(key, time=nil)
    time ||= Time.now().to_s
    settings = emails_received
    settings[key] = time
    self.emails = JSON.dump settings
    self.save
  end


  # Notification preferences. 
  def subscription_settings(subdomain)

    notifier_config = Notifier::config(subdomain)
    my_subs = Oj.load(subscriptions || "{}")[subdomain.id.to_s] || {}

    for event, config in notifier_config
      if config.key? 'allowed'
        next if !config['allowed'].call(self, subdomain)
      end
      
      if my_subs.key?(event)
        my_subs[event].merge! config
      else 
        my_subs[event] = config
      end

      if !my_subs[event].key?('email_trigger')
        my_subs[event]['email_trigger'] = my_subs[event]['email_trigger_default']
      end

    end

    my_subs['default_subscription'] = Notifier.default_subscription(subdomain)
    if !my_subs.key?('send_emails')
      my_subs['send_emails'] = my_subs['default_subscription']
    end

    my_subs
  end

  def update_subscription_key(key, value, hash={})
    sub_settings = subscription_settings(current_subdomain)
    return if !hash[:force] && sub_settings.key?(key)

    sub_settings[key] = value
    self.subscriptions = update_subscriptions(sub_settings)
    save
  end

  def update_subscriptions(new_settings, subdomain = nil)
    subdomain ||= current_subdomain

    subs = Oj.load(subscriptions || "{}")
    subs[subdomain.id.to_s] = new_settings

    # Strip out unnecessary items that we can reconstruct from the 
    # notification configuration 
    clean = proc do |k, v|        

      if v.respond_to?(:key?)
        if v.key?('default_subscription') && 
            v['default_subscription'] == v['subscription']
          v.delete('subscription')
        elsif v.key?('default_email_trigger') && 
            v['default_email_trigger'] == v['email_trigger']
          v.delete('email_trigger')
        end

        v.delete_if(&clean) # recurse if v is a hash
      end

      # 'proposal' and 'subdomain' in the list below is temporary for some migrations...
      # feel free to remove junish
      v.respond_to?(:key) && v.keys().length == 0 || \
      ['proposal', 'subdomain', 'subscription_options', 'ui_label', \
       'default_subscription', 'default_email_trigger'].include?(k)

    end

    subs.delete_if &clean

    JSON.dump subs
  end

  def avatar_url_provided?
    !self.avatar_url.blank?
  end

  def download_remote_image
    if self.downloaded.nil?
      self.downloaded = true
      self.avatar_url = self.avatar_remote_url if avatar_url.nil?
      io = open(URI.parse(self.avatar_url))
      def io.original_filename; base_uri.path.split('/').last; end

      self.avatar = io if !(io.original_filename.blank?)
      self.avatar_remote_url = avatar_url
      self.avatar_url = nil
    end

  end


  def key
    "/user/#{self.id}"
  end

  def username
    name ? 
      name
      : email ? 
        email.split('@')[0]
        : "#{current_subdomain.app_title or current_subdomain.name} participant"
  end
  
  def first_name
    username.split(' ')[0]
  end

  def short_name
    split = username.split(' ')
    if split.length > 1
      return "#{split[0][0]}. #{split[-1]}"
    end
    return split[0]  
  end


  def auth_token(subdomain = nil)
    subdomain ||= current_subdomain
    ApplicationController.MD5_hexdigest("#{self.email}#{self.unique_token}#{subdomain.name}")
  end

  def add_token
    self.unique_token = SecureRandom.hex(10)
    self.save
  end

  def self.add_token
    User.where(:unique_token => nil).each do |u|
      u.unique_token
    end
  end

  def avatar_link(img_type='small')
    if self.avatar_file_name
      "#{Rails.application.config.action_controller.asset_host || ''}/system/avatars/#{self.id}/#{img_type}/#{self.avatar_file_name}"
    else 
      nil 
    end
  end

  # Check to see if this user has been referenced by email in any 
  # roles or permissions settings. If so, replace the email with the
  # user's key. 
  def update_roles_and_permissions
    ActsAsTenant.without_tenant do 
      for cls in [Subdomain, Proposal]
        objs_with_user_in_role = cls.where("roles like '%\"#{self.email}\"%'") 
                                         # this is case insensitive

        for obj in objs_with_user_in_role
          pp "UPDATING ROLES, replacing #{self.email} with #{self.id} for #{obj.name}"
          obj.roles = obj.roles.gsub /\"#{self.email}\"/i, "\"/user/#{self.id}\""
          obj.save
        end
      end
    end
  end


  def absorb (user)
    return if not (self and user)

    older_user = self.id #user that will do the absorbing
    newer_user = user.id #user that will be absorbed

    puts("Merging!  Kill User #{newer_user}, put into User #{older_user}")

    return if older_user == newer_user
    
    dirty_key("/current_user") # in case absorb gets called outside 
                               # of CurrentUserController

    # Not only do we need to merge the user objects, but we'll need to
    # merge their opinion objects too.

    # To do this, we take the following steps
    #  1. Merge both users' opinions
    #  2. Change user_id for every object that has one to the new user_id
    #  3. Delete the old user

    # 1. Merge opinions
    #    ASSUMPTION: The Opinion of the user being absorbed is _newer_ than 
    #                the Opinion of the user doing the absorbtion. 
    #                This is currently TRUE for considerit. 
    #    TODO: Reconsider this assumption. Should we use Opinion.updated_at to 
    #          decide which is the new one and which is the old, and consequently 
    #          which gets absorbed into the other?
    new_ops = Opinion.where(:user_id => newer_user)
    old_ops = Opinion.where(:user_id => older_user)
    puts("Merging opinions from #{old_ops.map{|o| o.id}} to #{new_ops.map{|o| o.id}}")

    for new_op in new_ops

      # we only need to absorb this user if they've dragged the slider 
      # or included a point
      # ATTENTION!! This will delete someone's opinion if they vote exactly neutral and 
      #             didn't include any points (and they're logging in)
      if new_op.stance == 0 && (new_op.point_inclusions == '[]' || new_op.point_inclusions.length == 0)
        new_op.destroy
        next 
      end

      puts("Looking for opinion to absorb into #{new_op.id}...")
      old_op = Opinion.where(:user_id => older_user,
                             :proposal_id => new_op.proposal.id).first

      if old_op
        puts("Found opinion to absorb into #{new_op.id}: #{old_op.id}")
        # Merge the two opinions. We'll absorb the old opinion into the new one!
        # Update new_ops' user_id to the old user. 
        new_op.absorb(old_op, true)
      else
        # if this is the first time this user is saving an opinion for this proposal
        # we'll just change the user id of the opinion, seeing as there isn't any
        # opinion to absorb into
        new_op.user_id = older_user
        new_op.save
        dirty_key("/opinion/#{new_op.id}")
      end
      
    end

    # 2. Change user_id columns over in bulk
    # TRAVIS: Opinion & Inclusion is taken care of when absorbing an Opinion

    # Bulk updates...
    for table in [Point, Proposal, Comment] 

      # First, remember what we're dirtying
      table.where(:user_id => newer_user).each{|x| dirty_key("/#{table.name.downcase}/#{x.id}")}
      table.where(:user_id => newer_user).update_all(user_id: older_user)
    end

    # log table, which doesn't use user_id
    Log.where(:who => newer_user).update_all(who: older_user)

    subs = Oj.load(self.active_in || '[]').concat(Oj.load(user.active_in || '[]')).uniq
    self.active_in = JSON.dump subs
    save 

    # 3. Delete the old user
    # TODO: Enable this once we're confident everything is working.
    #       I see that this is being done in CurrentUserController#replace_user. 
    #       Where should it live? 
    # user.destroy()

  end


  def self.purge
    users = User.all.map {|u| u.id}
    missing_users = []
    classes = [Opinion, Point, Inclusion]
    classes.each do |cls|
      cls.where("user_id IS NOT NULL AND user_id NOT IN (?)", users ).each do |r|
        missing_users.push r.user_id
      end
    end
    classes.each do |cls|
      cls.where("user_id in (?)", missing_users.uniq).delete_all
    end
  end

  def self.get_saml_settings(url_base, sso_idp)
    # should retrieve SAML-settings based on subdomain, IP-address, NameID or similar
    settings = OneLogin::RubySaml::Settings.new

    url_base ||= "http://localhost:3000"

    # When disabled, saml validation errors will raise an exception.
    settings.soft = true


    if sso_idp =='dtu'
      # Hack for DTU b/c they use a case sensitive ADSF based on application name
      dtu_url_base = "https://saml_auth.Consider.it"
      settings.issuer                         = dtu_url_base + "/saml/dtu"
      # assertion_consumer_service_url should stay lower case
      settings.assertion_consumer_service_url                  = "https://saml_auth.consider.it/saml/acs"
      settings.assertion_consumer_logout_service_url = dtu_url_base + "/saml/logout"
    else
      settings.issuer                         = url_base + "/saml/metadata"
      settings.assertion_consumer_service_url = url_base + "/saml/acs"
      settings.assertion_consumer_logout_service_url = url_base + "/saml/logout"
    end

    # Example settings data, replace this values with Delft settings!
    # TODO replace example.com settings with Delft IDP settings
    if sso_idp == 'dtu' 

      # IdP section for Onelogin IDP used in development
      settings.idp_entity_id                  = "http://sts.ait.dtu.dk/adfs/services/trust"
      settings.idp_sso_target_url             = "https://sts.ait.dtu.dk/adfs/ls/"
      settings.idp_slo_target_url             = "https://sts.ait.dtu.dk/adfs/ls/"

      settings.idp_cert                       = "-----BEGIN CERTIFICATE-----
MIIFUzCCBDugAwIBAgIQCXIDJ75zmABJOlKt52MUzTANBgkqhkiG9w0BAQsFADBk
MQswCQYDVQQGEwJOTDEWMBQGA1UECBMNTm9vcmQtSG9sbGFuZDESMBAGA1UEBxMJ
QW1zdGVyZGFtMQ8wDQYDVQQKEwZURVJFTkExGDAWBgNVBAMTD1RFUkVOQSBTU0wg
Q0EgMzAeFw0xNjA5MjEwMDAwMDBaFw0xOTA5MjYxMjAwMDBaMIGSMQswCQYDVQQG
EwJESzEQMA4GA1UECBMHRGVubWFyazEXMBUGA1UEBxMOS29uZ2VucyBMeW5nZXkx
KDAmBgNVBAoTH1RlY2huaWNhbCBVbml2ZXJzaXR5IG9mIERlbm1hcmsxDDAKBgNV
BAsTA0FJVDEgMB4GA1UEAxMXdG9rZW5zaWduaW5nLmFpdC5kdHUuZGswggEiMA0G
CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC9qeLkARtUlXLxGzbRL6kh9XfYlb33
A16yBWVQc3hu6kXM5pYp+lrR5U9jg2Y+r8KUYJPj6KRQP7x+uDvs9KJv8J+yjgDl
QwIBqzr/xN4y5YJh7VDegLsex9lGBus2jFPMhdkcvY+UA41L7J1kSBa3OG9lQuGK
3FXuYnUcPq6p40siais/KzFsxr7OEkLiYtnSQOuZY/30HEKZXSjbNdUawIBY56WI
jsDFWlYPq2Cw+1xf9a0zEvKW7KSwnX8ZI1TTNYGzRFoRDOxfd23tFNBWz8AQyQhM
5x2iPMAQTL9XmvEUtQP1U+t5PqRL440CKqrQKTZ/RhnTeyzy+IR4QzlxAgMBAAGj
ggHQMIIBzDAfBgNVHSMEGDAWgBRn/YggFCeYxwnSJRm76VERY3VQYjAdBgNVHQ4E
FgQUZa1e2q8n+dH5tBV7Pr9aQZ1dL+YwIgYDVR0RBBswGYIXdG9rZW5zaWduaW5n
LmFpdC5kdHUuZGswDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMB
BggrBgEFBQcDAjBrBgNVHR8EZDBiMC+gLaArhilodHRwOi8vY3JsMy5kaWdpY2Vy
dC5jb20vVEVSRU5BU1NMQ0EzLmNybDAvoC2gK4YpaHR0cDovL2NybDQuZGlnaWNl
cnQuY29tL1RFUkVOQVNTTENBMy5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAQEw
KjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZn
gQwBAgIwbgYIKwYBBQUHAQEEYjBgMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
aWdpY2VydC5jb20wOAYIKwYBBQUHMAKGLGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
LmNvbS9URVJFTkFTU0xDQTMuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEL
BQADggEBAAFMSeFpnuVqh74FUi4IAUr7HmXO0nXoe6QvSDDUGmufdLX9wLt+w+r8
bjJ82X648z1WYqf5rQzwWtqUXijVX0XdTdSTcOQa98mmgSxmlIvNfJ6mzu0VWRNt
99uj6xzX2ignSZrMlE/PSbDYou5Bo3dXAhqn/UecbT99kpsnOTWjnwSsULPCG4Fj
AutRZorKDmnSzIAMFj/KqGcYmh83cvIvP0Bylad5C11gwcb/UUjxNBuqjuyQpU48
he8kj0/4x2nej8/Xph+S+JREsQQLZWISmCToQX1EWZCt2MDbPYhl4p+Oy9dPIoO9
54jbX2F6embwMrKWjsQegQIFGSvCum8=
-----END CERTIFICATE-----"


      # or settings.idp_cert_fingerprint           = "3B:05:BE:0A:EC:84:CC:D4:75:97:B3:A2:22:AC:56:21:44:EF:59:E6"
      #    settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

      settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

      # Security section
      settings.security[:authn_requests_signed] = true 
      settings.security[:logout_requests_signed] = true
      settings.security[:logout_responses_signed] = true 
      settings.security[:metadata_signed] = true 
      settings.security[:digest_method] = XMLSecurity::Document::SHA1
      settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

      # adding some test parameters
      settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      settings.security[:embed_sign] = false 

      settings.certificate = "-----BEGIN CERTIFICATE-----
MIIDGjCCAoOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBqTELMAkGA1UEBhMCdXMx
FjAUBgNVBAgMDU1BU1NBQ0hVU0VUVFMxFDASBgNVBAoMC0NvbnNpZGVyLml0MR4w
HAYDVQQDDBVzYW1sX2F1dGguY29uc2lkZXIuaXQxEzARBgNVBAcMClNvbWVydmls
bGUxEzARBgNVBAsMClNvbWVydmlsbGUxIjAgBgkqhkiG9w0BCQEWE25hdGhhbi5t
c0BnbWFpbC5jb20wHhcNMTYxMDI1MjEwMDE5WhcNMTcxMDExMjEwMDE5WjCBqTEL
MAkGA1UEBhMCdXMxFjAUBgNVBAgMDU1BU1NBQ0hVU0VUVFMxFDASBgNVBAoMC0Nv
bnNpZGVyLml0MR4wHAYDVQQDDBVzYW1sX2F1dGguY29uc2lkZXIuaXQxEzARBgNV
BAcMClNvbWVydmlsbGUxEzARBgNVBAsMClNvbWVydmlsbGUxIjAgBgkqhkiG9w0B
CQEWE25hdGhhbi5tc0BnbWFpbC5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJ
AoGBAK8D5voI8gArtI3E539bqIi3erH0cCJiBxBua3aQV6JHeLGnpsUNLDp+NSL2
xmbuUoueZSKukmNwnl7P6IxW+oOq+yDXpQgkP5tBEA9RYIx8YAMud4VNL6Loagry
MV+XMkhr2E6XEH1MwAPmTWVLtv6y6R1XX6aq5th/MEYrvG5dAgMBAAGjUDBOMB0G
A1UdDgQWBBTnBSlmyjkPVGNQ6rXBJoYDDJAKSDAfBgNVHSMEGDAWgBTnBSlmyjkP
VGNQ6rXBJoYDDJAKSDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBDQUAA4GBAKsL
s8BuNTDDQ3fR9hs1yoHnmUarRACTvT21U7f8oWL6FosAoS31P5cmQyci8cNgFmjL
s0xe0+m9H9wvuPz7st+wagwzsDPBsXadEnLh/2pv+6L75DiYpGEvie9iPPlqwWde
DEQNIpGcHW/8vNq9GWt/Sz/B3JCYSdJeQtUZZUaR
-----END CERTIFICATE-----"
      settings.private_key = "-----BEGIN PRIVATE KEY-----
MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAK8D5voI8gArtI3E
539bqIi3erH0cCJiBxBua3aQV6JHeLGnpsUNLDp+NSL2xmbuUoueZSKukmNwnl7P
6IxW+oOq+yDXpQgkP5tBEA9RYIx8YAMud4VNL6LoagryMV+XMkhr2E6XEH1MwAPm
TWVLtv6y6R1XX6aq5th/MEYrvG5dAgMBAAECgYEAl7vnXjGxNiquMBddqVJbLKT+
cBh/u5+HhlxlOPbts1kJr+StNrwz80aGZRjUbFsFH90ky8vUSPhTpdnVQQ8LwvrH
vjmIC0GJGPwAx8TCqG+5GQtGltH94XcTbgDOof0D/sQJl8UBxj3ORblskEd9v4Ty
po7wQZiLjsH1UCgmgVUCQQDVjZr40iKckZejysPwA57IOtdifI/gelDLiWkIPzFy
4DTCtXw4FCWt8yEj2q88DTgSXYP35E3uloVP7UgW883bAkEA0c1XlXRYKo2haB/b
5uVoyMBIwI94Pqdv6HlcWhFhylhbxrDS1j/Q6B3ZDS9CmPuWXFb6CDXflSj0RxdV
VnnWJwJATaTSt60PUIXO8IqEevuV+48JSJGpbiCKx7YKLilrvSyvgiuiInGQ0ZIY
doTIOblErci6dqLXguvPRKQtFctHCQJBAKqoKm8itTjf/gQRrjFSOHrblhI0Ya4t
SqVCWrHU48PRPc4QNWAbhtXYuZ6066o/M96mzTlygQz2xEUzoLH35w8CQQCGRG5f
ERqJ0qeWl/EcDLOcNFxEQY/w+20uIA6VeRVkhBLkSlNrbaKnB9jhmHObGi5AVt8z
plfUJ9UwDhWH+xPo
-----END PRIVATE KEY-----"



    elsif current_subdomain.host_with_port == 'test.example.com:80'
      # IdP section
      settings.idp_entity_id                  = ""
      settings.idp_sso_target_url             = ""
      settings.idp_slo_target_url             = ""

    settings.idp_cert                       = "-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----"

      # or settings.idp_cert_fingerprint           = "3B:05:BE:0A:EC:84:CC:D4:75:97:B3:A2:22:AC:56:21:44:EF:59:E6"
      #    settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

      settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

      # Security section
      settings.security[:authn_requests_signed] = false
      settings.security[:logout_requests_signed] = false
      settings.security[:logout_responses_signed] = false
      settings.security[:metadata_signed] = false
      settings.security[:digest_method] = XMLSecurity::Document::SHA1
      settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

    elsif sso_idp == 'standardminds'
      # IdP section for Onelogin IDP used in development
      settings.idp_entity_id                  = "https://app.onelogin.com/saml/metadata/585764"
      settings.idp_sso_target_url             = "https://standardminds-dev.onelogin.com/trust/saml2/http-post/sso/585764"
      settings.idp_slo_target_url             = "https://standardminds-dev.onelogin.com/trust/saml2/http-redirect/slo/585764"

      settings.idp_cert                       = "-----BEGIN CERTIFICATE-----
MIIEHTCCAwWgAwIBAgIUahG83qLFXCyf8o3d5J5I5mdfSbkwDQYJKoZIhvcNAQEF
BQAwWjELMAkGA1UEBhMCVVMxEzARBgNVBAoMCkNvbnNpZGVyaXQxFTATBgNVBAsM
DE9uZUxvZ2luIElkUDEfMB0GA1UEAwwWT25lTG9naW4gQWNjb3VudCA5MTU2NDAe
Fw0xNjA5MDkwMzQzMzZaFw0yMTA5MTAwMzQzMzZaMFoxCzAJBgNVBAYTAlVTMRMw
EQYDVQQKDApDb25zaWRlcml0MRUwEwYDVQQLDAxPbmVMb2dpbiBJZFAxHzAdBgNV
BAMMFk9uZUxvZ2luIEFjY291bnQgOTE1NjQwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC6P1KSXOUJ99lFoaGZHMokRropHQfiRVubCtWEbezWDxGwdsnr
/raowJJXKQIalcVFJHIao5I9cbXrcgpvmElgxaMTWm+rInsY1f2y5yUM321BC/3+
4q8N8xvCBhNEUD0O9xkcHcsMAXGu33vg0YSFYUd99aYoTeUwG6urpz6/b4JldMw3
7ygOCssa9m6Ux9k4rbId9eYXiWgwrmrtEktUggYKfzIqhD/2KoFgzCIdVFMdYyja
l2mPEbf+oav/5y6HO/gtK/DnZYW1LDs0c3Nwtab1bvmP0J+8mbmLDTRA2hyTBtQz
GeBiUz9g8S1A68ezvulYccMmgDR6qdb7vQOZAgMBAAGjgdowgdcwDAYDVR0TAQH/
BAIwADAdBgNVHQ4EFgQUpppEHxiKI9BJJeJB4GAjaLBuZlYwgZcGA1UdIwSBjzCB
jIAUpppEHxiKI9BJJeJB4GAjaLBuZlahXqRcMFoxCzAJBgNVBAYTAlVTMRMwEQYD
VQQKDApDb25zaWRlcml0MRUwEwYDVQQLDAxPbmVMb2dpbiBJZFAxHzAdBgNVBAMM
Fk9uZUxvZ2luIEFjY291bnQgOTE1NjSCFGoRvN6ixVwsn/KN3eSeSOZnX0m5MA4G
A1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQUFAAOCAQEANmz1PRfgM8UEaWU2dUQ6
p9LKzrTPlNmGY/pNFaGj42j/G8Q1qNPUnrhbitj8pdlr0vAHLQQkMvcICtmeS8UN
bxaJ1YbN8s3o0twOXguzC19a0hkSyNdDCO+GgqazNnMzYmL+KbvdgVKCUs1kzI5Q
8M8rH09auNVKPJ+QtaXbBln8DJJ2L9/Db6ujQlKR0ol2gotpMuoxCRtUMj9UmMM6
euAP3Pt3b49r0igIPIwW9P73FOCmwFRURvFXMaj/M8MpJOxJ8a7CIvqaQXhW1voh
BORjb2jFjB5kon9QH6kPg2KnYCThSe4OE5f5bv6gNhcfATYAtEWMKbVLhTDWXMfL
xA==
-----END CERTIFICATE-----"

      # or settings.idp_cert_fingerprint           = "3B:05:BE:0A:EC:84:CC:D4:75:97:B3:A2:22:AC:56:21:44:EF:59:E6"
      #    settings.idp_cert_fingerprint_algorithm = XMLSecurity::Document::SHA1

      settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

      # Security section
      settings.security[:authn_requests_signed] = true 
      settings.security[:logout_requests_signed] = false
      settings.security[:logout_responses_signed] = false
      settings.security[:metadata_signed] = true 
      settings.security[:digest_method] = XMLSecurity::Document::SHA1
      settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

      settings.certificate = "-----BEGIN CERTIFICATE-----
MIIDGjCCAoOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBqTELMAkGA1UEBhMCdXMx
FjAUBgNVBAgMDU1BU1NBQ0hVU0VUVFMxFDASBgNVBAoMC0NvbnNpZGVyLml0MR4w
HAYDVQQDDBVzYW1sX2F1dGguY29uc2lkZXIuaXQxEzARBgNVBAcMClNvbWVydmls
bGUxEzARBgNVBAsMClNvbWVydmlsbGUxIjAgBgkqhkiG9w0BCQEWE25hdGhhbi5t
c0BnbWFpbC5jb20wHhcNMTYxMDI1MjEwMDE5WhcNMTcxMDExMjEwMDE5WjCBqTEL
MAkGA1UEBhMCdXMxFjAUBgNVBAgMDU1BU1NBQ0hVU0VUVFMxFDASBgNVBAoMC0Nv
bnNpZGVyLml0MR4wHAYDVQQDDBVzYW1sX2F1dGguY29uc2lkZXIuaXQxEzARBgNV
BAcMClNvbWVydmlsbGUxEzARBgNVBAsMClNvbWVydmlsbGUxIjAgBgkqhkiG9w0B
CQEWE25hdGhhbi5tc0BnbWFpbC5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJ
AoGBAK8D5voI8gArtI3E539bqIi3erH0cCJiBxBua3aQV6JHeLGnpsUNLDp+NSL2
xmbuUoueZSKukmNwnl7P6IxW+oOq+yDXpQgkP5tBEA9RYIx8YAMud4VNL6Loagry
MV+XMkhr2E6XEH1MwAPmTWVLtv6y6R1XX6aq5th/MEYrvG5dAgMBAAGjUDBOMB0G
A1UdDgQWBBTnBSlmyjkPVGNQ6rXBJoYDDJAKSDAfBgNVHSMEGDAWgBTnBSlmyjkP
VGNQ6rXBJoYDDJAKSDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBDQUAA4GBAKsL
s8BuNTDDQ3fR9hs1yoHnmUarRACTvT21U7f8oWL6FosAoS31P5cmQyci8cNgFmjL
s0xe0+m9H9wvuPz7st+wagwzsDPBsXadEnLh/2pv+6L75DiYpGEvie9iPPlqwWde
DEQNIpGcHW/8vNq9GWt/Sz/B3JCYSdJeQtUZZUaR
-----END CERTIFICATE-----"
      settings.private_key = "-----BEGIN PRIVATE KEY-----
MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAK8D5voI8gArtI3E
539bqIi3erH0cCJiBxBua3aQV6JHeLGnpsUNLDp+NSL2xmbuUoueZSKukmNwnl7P
6IxW+oOq+yDXpQgkP5tBEA9RYIx8YAMud4VNL6LoagryMV+XMkhr2E6XEH1MwAPm
TWVLtv6y6R1XX6aq5th/MEYrvG5dAgMBAAECgYEAl7vnXjGxNiquMBddqVJbLKT+
cBh/u5+HhlxlOPbts1kJr+StNrwz80aGZRjUbFsFH90ky8vUSPhTpdnVQQ8LwvrH
vjmIC0GJGPwAx8TCqG+5GQtGltH94XcTbgDOof0D/sQJl8UBxj3ORblskEd9v4Ty
po7wQZiLjsH1UCgmgVUCQQDVjZr40iKckZejysPwA57IOtdifI/gelDLiWkIPzFy
4DTCtXw4FCWt8yEj2q88DTgSXYP35E3uloVP7UgW883bAkEA0c1XlXRYKo2haB/b
5uVoyMBIwI94Pqdv6HlcWhFhylhbxrDS1j/Q6B3ZDS9CmPuWXFb6CDXflSj0RxdV
VnnWJwJATaTSt60PUIXO8IqEevuV+48JSJGpbiCKx7YKLilrvSyvgiuiInGQ0ZIY
doTIOblErci6dqLXguvPRKQtFctHCQJBAKqoKm8itTjf/gQRrjFSOHrblhI0Ya4t
SqVCWrHU48PRPc4QNWAbhtXYuZ6066o/M96mzTlygQz2xEUzoLH35w8CQQCGRG5f
ERqJ0qeWl/EcDLOcNFxEQY/w+20uIA6VeRVkhBLkSlNrbaKnB9jhmHObGi5AVt8z
plfUJ9UwDhWH+xPo
-----END PRIVATE KEY-----"


    # NATHAN adding some test parameters
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
    settings.security[:embed_sign] = false 

    else
      raise "IdP settings not found for this subdomain!"
    end

    settings
  end

end
