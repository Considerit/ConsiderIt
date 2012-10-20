# RailsAdmin config file. Generated on September 15, 2012 18:44
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|

  # If your default_local is different from :en, uncomment the following 2 lines and set your default locale here:
  # require 'i18n'
  # I18n.default_locale = :de

  config.current_user_method { current_user } # auto-generated

  # If you want to track changes on your models:
  # config.audit_with :history, User

  # Or with a PaperTrail: (you need to install it first)
  config.audit_with :paper_trail, User

  # Set the admin name here (optional second array element will appear in a beautiful RailsAdmin red ©)
  config.main_app_name = ['Consider It', 'Admin']
  # or for a dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

  config.authorize_with :cancan

  #  ==> Global show view settings
  # Display empty fields in show views
  # config.compact_show_view = false

  #  ==> Global list view settings
  # Number of default rows per-page:
  # config.default_items_per_page = 20

  #  ==> Included models
  # Add all excluded models here:
  # config.excluded_models = [Account, Activity, ActsAsFollowable::Follow, Comment, DelayedMailhopper::Email, Domain, DomainMap, Inclusion, Mailhopper::Email, Point, PointListing, PointSimilarity, Position, Proposal, Reflect::ReflectBullet, Reflect::ReflectBulletRevision, Reflect::ReflectHighlight, Reflect::ReflectResponse, Reflect::ReflectResponseRevision, Session, User]

  # Add models here if you want to go 'whitelist mode':
  # config.included_models = [Account, Activity, ActsAsFollowable::Follow, Comment, DelayedMailhopper::Email, Domain, DomainMap, Inclusion, Mailhopper::Email, Point, PointListing, PointSimilarity, Position, Proposal, Reflect::ReflectBullet, Reflect::ReflectBulletRevision, Reflect::ReflectHighlight, Reflect::ReflectResponse, Reflect::ReflectResponseRevision, Session, User]

  # Application wide tried label methods for models' instances
  # config.label_methods << :description # Default is [:name, :title]

  #  ==> Global models configuration
  # config.models do
  #   # Configuration here will affect all included models in all scopes, handle with care!
  #
  #   list do
  #     # Configuration here will affect all included models in list sections (same for show, export, edit, update, create)
  #
  #     fields_of_type :date do
  #       # Configuration here will affect all date fields, in the list section, for all included models. See README for a comprehensive type list.
  #     end
  #   end
  # end
  #

  classes = ['Activity', 'Inclusion', 'Point', 'PointListing', 'Position', 'Proposal', 'User', 'Commentable::Comment', 'Moderatable::Moderation', 'Reflect::ReflectBullet', 'Reflect::ReflectBulletRevision', 'Reflect::ReflectHighlight', 'Reflect::ReflectResponse', 'Reflect::ReflectResponseRevision', 'Assessable::Claim', 'Assessable::Request', 'Assessable::Assessment']
  classes.each do |cls|
    config.model cls do
      edit do
        exclude_fields :account_id, :account
      end
    end
  end



  #  ==> Model specific configuration
  # Keep in mind that *all* configuration blocks are optional.
  # RailsAdmin will try his best to provide the best defaults for each section, for each field.
  # Try to override as few things as possible, in the most generic way. Try to avoid setting labels for models and attributes, use ActiveRecord I18n API instead.
  # Less code is better code!
  # config.model MyModel do
  #   # Cross-section field configuration
  #   object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #   label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #   label_plural 'My models'      # Same, plural
  #   weight -1                     # Navigation priority. Bigger is higher.
  #   parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #   navigation_label              # Sets dropdown entry's name in navigation. Only for parents!
  #   # Section specific configuration:
  #   list do
  #     filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #     items_per_page 100    # Override default_items_per_page
  #     sort_by :id           # Sort column (default is primary key)
  #     sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     # Here goes the fields configuration for the list view
  #   end
  # end

  # Your model's configuration, to help you get started:

  # All fields marked as 'hidden' won't be shown anywhere in the rails_admin unless you mark them as visible. (visible(true))

  # config.model Account do
  #   # Found associations:
  #     configure :proposals, :has_many_association 
  #     configure :points, :has_many_association 
  #     configure :positions, :has_many_association 
  #     configure :domains, :has_many_association 
  #     configure :users, :has_many_association 
  #     configure :comments, :has_many_association 
  #     configure :activities, :has_many_association 
  #     configure :reflect_bullets, :has_many_association 
  #     configure :reflect_responses, :has_many_association 
  #     configure :follows, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :identifier, :string 
  #     configure :theme, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :app_title, :string 
  #     configure :contact_email, :string 
  #     configure :app_proposal_creation_permission, :integer 
  #     configure :socmedia_facebook_page, :string 
  #     configure :socmedia_twitter_account, :string 
  #     configure :analytics_google, :string 
  #     configure :app_require_registration_for_perspective, :boolean 
  #     configure :socmedia_facebook_client, :string 
  #     configure :socmedia_facebook_secret, :string 
  #     configure :socmedia_twitter_consumer_key, :string 
  #     configure :socmedia_twitter_consumer_secret, :string 
  #     configure :socmedia_twitter_oauth_token, :string 
  #     configure :socmedia_twitter_oauth_token_secret, :string 
  #     configure :requires_civility_pledge_on_registration, :boolean 
  #     configure :followable_last_notification_milestone, :integer 
  #     configure :followable_last_notification, :datetime 
  #     configure :default_hashtags, :string 
  #     configure :tweet_notifications, :boolean 
  #     configure :host, :string 
  #     configure :host_with_port, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Activity do
  #   # Found associations:
  #     configure :action, :polymorphic_association 
  #     configure :account, :belongs_to_association 
  #     configure :user, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :action_type, :string         # Hidden 
  #     configure :action_id, :integer         # Hidden 
  #     configure :account_id, :integer         # Hidden 
  #     configure :user_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model ActsAsFollowable::Follow do
  #   # Found associations:
  #     configure :user, :belongs_to_association 
  #     configure :followable, :polymorphic_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :user_id, :integer         # Hidden 
  #     configure :followable_id, :integer         # Hidden 
  #     configure :followable_type, :string         # Hidden 
  #     configure :follow, :boolean 
  #     configure :explicit, :boolean 
  #     configure :account_id, :integer 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Comment do
  #   # Found associations:
  #     configure :commentable, :polymorphic_association 
  #     configure :user, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :reflect_bullets, :has_many_association 
  #     configure :reflect_bullet_revisions, :has_many_association 
  #     configure :activities, :has_many_association 
  #     configure :versions, :has_many_association         # Hidden 
  #     configure :follows, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :commentable_id, :integer         # Hidden 
  #     configure :commentable_type, :string         # Hidden 
  #     configure :title, :string 
  #     configure :body, :text 
  #     configure :subject, :string 
  #     configure :user_id, :integer         # Hidden 
  #     configure :parent_id, :integer 
  #     configure :lft, :integer 
  #     configure :rgt, :integer 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :point_id, :integer 
  #     configure :option_id, :integer 
  #     configure :passes_moderation, :boolean 
  #     configure :account_id, :integer         # Hidden 
  #     configure :followable_last_notification_milestone, :integer 
  #     configure :followable_last_notification, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model DelayedMailhopper::Email do
  #   # Found associations:
  #   # Found columns:
  #     configure :id, :integer 
  #     configure :from_address, :string 
  #     configure :reply_to_address, :string 
  #     configure :subject, :string 
  #     configure :to_address, :text 
  #     configure :cc_address, :text 
  #     configure :bcc_address, :text 
  #     configure :content, :text 
  #     configure :sent_at, :datetime 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Domain do
  #   # Found associations:
  #     configure :account, :belongs_to_association 
  #     configure :domain_maps, :has_many_association 
  #     configure :users, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :identifier, :integer 
  #     configure :name, :string 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model DomainMap do
  #   # Found associations:
  #     configure :proposal, :belongs_to_association 
  #     configure :domain, :belongs_to_association 
  #     configure :account, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :proposal_id, :integer         # Hidden 
  #     configure :domain_id, :integer         # Hidden 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Inclusion do
  #   # Found associations:
  #     configure :proposal, :belongs_to_association 
  #     configure :position, :belongs_to_association 
  #     configure :point, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :versions, :has_many_association         # Hidden 
  #     configure :activities, :has_many_association 
  #     configure :point_listing, :has_one_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :proposal_id, :integer         # Hidden 
  #     configure :position_id, :integer         # Hidden 
  #     configure :point_id, :integer         # Hidden 
  #     configure :user_id, :integer         # Hidden 
  #     configure :session_id, :integer 
  #     configure :included_as_pro, :boolean 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :deleted_at, :datetime 
  #     configure :version, :integer 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Mailhopper::Email do
  #   # Found associations:
  #   # Found columns:
  #     configure :id, :integer 
  #     configure :from_address, :string 
  #     configure :reply_to_address, :string 
  #     configure :subject, :string 
  #     configure :to_address, :text 
  #     configure :cc_address, :text 
  #     configure :bcc_address, :text 
  #     configure :content, :text 
  #     configure :sent_at, :datetime 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Point do
  #   # Found associations:
  #     configure :proposal, :belongs_to_association 
  #     configure :position, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :comments, :has_many_association 
  #     configure :activities, :has_many_association 
  #     configure :follows, :has_many_association 
  #     configure :versions, :has_many_association         # Hidden 
  #     configure :inclusions, :has_many_association 
  #     configure :point_listings, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :proposal_id, :integer         # Hidden 
  #     configure :position_id, :integer         # Hidden 
  #     configure :user_id, :integer         # Hidden 
  #     configure :session_id, :integer 
  #     configure :nutshell, :text 
  #     configure :text, :text 
  #     configure :is_pro, :boolean 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :num_inclusions, :integer 
  #     configure :unique_listings, :integer 
  #     configure :score, :float 
  #     configure :attention, :float 
  #     configure :persuasiveness, :float 
  #     configure :appeal, :float 
  #     configure :score_stance_group_0, :float 
  #     configure :score_stance_group_1, :float 
  #     configure :score_stance_group_2, :float 
  #     configure :score_stance_group_3, :float 
  #     configure :score_stance_group_4, :float 
  #     configure :score_stance_group_5, :float 
  #     configure :score_stance_group_6, :float 
  #     configure :deleted_at, :datetime 
  #     configure :version, :integer 
  #     configure :published, :boolean 
  #     configure :hide_name, :boolean 
  #     configure :share, :boolean 
  #     configure :passes_moderation, :boolean 
  #     configure :account_id, :integer         # Hidden 
  #     configure :followable_last_notification_milestone, :integer 
  #     configure :followable_last_notification, :datetime 
  #     configure :comment_count, :integer 
  #     configure :point_link_count, :integer 
  #     configure :includers, :string 
  #     configure :divisiveness, :float   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model PointListing do
  #   # Found associations:
  #     configure :proposal, :belongs_to_association 
  #     configure :position, :belongs_to_association 
  #     configure :point, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :inclusion, :belongs_to_association 
  #     configure :account, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :proposal_id, :integer         # Hidden 
  #     configure :position_id, :integer         # Hidden 
  #     configure :point_id, :integer         # Hidden 
  #     configure :user_id, :integer         # Hidden 
  #     configure :inclusion_id, :integer         # Hidden 
  #     configure :session_id, :integer 
  #     configure :context, :integer 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model PointSimilarity do
  #   # Found associations:
  #     configure :p1, :belongs_to_association 
  #     configure :p2, :belongs_to_association 
  #     configure :proposal, :belongs_to_association 
  #     configure :user, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :p1_id, :integer         # Hidden 
  #     configure :p2_id, :integer         # Hidden 
  #     configure :proposal_id, :integer         # Hidden 
  #     configure :user_id, :integer         # Hidden 
  #     configure :value, :integer 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Position do
  #   # Found associations:
  #     configure :proposal, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :inclusions, :has_many_association 
  #     configure :points, :has_many_association 
  #     configure :point_listings, :has_many_association 
  #     configure :comments, :has_many_association 
  #     configure :versions, :has_many_association         # Hidden 
  #     configure :activities, :has_many_association 
  #     configure :follows, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :proposal_id, :integer         # Hidden 
  #     configure :user_id, :integer         # Hidden 
  #     configure :session_id, :integer 
  #     configure :explanation, :text 
  #     configure :stance, :float 
  #     configure :stance_bucket, :integer 
  #     configure :published, :boolean 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :deleted_at, :datetime 
  #     configure :version, :integer 
  #     configure :notification_demonstrated_interest, :boolean 
  #     configure :notification_point_subscriber, :boolean 
  #     configure :notification_perspective_subscriber, :boolean 
  #     configure :account_id, :integer         # Hidden 
  #     configure :notification_author, :boolean 
  #     configure :followable_last_notification_milestone, :integer 
  #     configure :followable_last_notification, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Proposal do
  #   # Found associations:
  #     configure :account, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :points, :has_many_association 
  #     configure :positions, :has_many_association 
  #     configure :inclusions, :has_many_association 
  #     configure :point_listings, :has_many_association 
  #     configure :point_similarities, :has_many_association 
  #     configure :domain_maps, :has_many_association 
  #     configure :follows, :has_many_association 
  #     configure :taggings, :has_many_association         # Hidden 
  #     configure :base_tags, :has_many_association         # Hidden 
  #     configure :tag_taggings, :has_many_association         # Hidden 
  #     configure :tags, :has_many_association         # Hidden 
  #     configure :activities, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :designator, :string 
  #     configure :category, :string 
  #     configure :name, :string 
  #     configure :short_name, :string 
  #     configure :description, :text 
  #     configure :image, :string 
  #     configure :url, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :domain, :string 
  #     configure :domain_short, :string 
  #     configure :long_description, :text 
  #     configure :additional_details, :text 
  #     configure :slider_prompt, :string 
  #     configure :considerations_prompt, :string 
  #     configure :statement_prompt, :string 
  #     configure :headers, :string 
  #     configure :entity, :string 
  #     configure :discussion_mode, :string 
  #     configure :enable_position_statement, :boolean 
  #     configure :account_id, :integer         # Hidden 
  #     configure :session_id, :string 
  #     configure :require_login, :boolean 
  #     configure :email_creator_per_position, :boolean 
  #     configure :long_id, :string 
  #     configure :admin_id, :string 
  #     configure :user_id, :integer         # Hidden 
  #     configure :slider_right, :string 
  #     configure :slider_left, :string 
  #     configure :trending, :float 
  #     configure :activity, :float 
  #     configure :provocative, :float 
  #     configure :contested, :float 
  #     configure :num_points, :integer 
  #     configure :num_pros, :integer 
  #     configure :num_cons, :integer 
  #     configure :num_comments, :integer 
  #     configure :num_inclusions, :integer 
  #     configure :num_perspectives, :integer 
  #     configure :num_supporters, :integer 
  #     configure :num_opposers, :integer 
  #     configure :num_views, :integer 
  #     configure :num_unpublished_positions, :integer 
  #     configure :followable_last_notification_milestone, :integer 
  #     configure :followable_last_notification, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Reflect::ReflectBullet do
  #   # Found associations:
  #     configure :comment, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :versions, :has_many_association         # Hidden 
  #     configure :revisions, :has_many_association 
  #     configure :responses, :has_many_association 
  #     configure :highlights, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :comment_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :account_id, :integer         # Hidden 
  #     configure :comment_type, :text   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Reflect::ReflectBulletRevision do
  #   # Found associations:
  #     configure :bullet, :belongs_to_association 
  #     configure :comment, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :activities, :has_many_association 
  #     configure :highlights, :has_many_association 
  #     configure :responses, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :bullet_id, :integer         # Hidden 
  #     configure :comment_id, :integer         # Hidden 
  #     configure :text, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :active, :boolean 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :account_id, :integer         # Hidden 
  #     configure :comment_type, :text   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Reflect::ReflectHighlight do
  #   # Found associations:
  #     configure :bullet, :belongs_to_association 
  #     configure :bullet_revision, :belongs_to_association 
  #     configure :account, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :bullet_id, :integer         # Hidden 
  #     configure :bullet_rev, :integer         # Hidden 
  #     configure :element_id, :string 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Reflect::ReflectResponse do
  #   # Found associations:
  #     configure :bullet, :belongs_to_association 
  #     configure :account, :belongs_to_association 
  #     configure :revisions, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :bullet_id, :integer         # Hidden 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Reflect::ReflectResponseRevision do
  #   # Found associations:
  #     configure :bullet, :belongs_to_association 
  #     configure :bullet_revision, :belongs_to_association 
  #     configure :response, :belongs_to_association 
  #     configure :user, :belongs_to_association 
  #     configure :account, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :bullet_id, :integer         # Hidden 
  #     configure :bullet_rev, :integer         # Hidden 
  #     configure :response_id, :integer         # Hidden 
  #     configure :text, :text 
  #     configure :user_id, :integer         # Hidden 
  #     configure :signal, :integer 
  #     configure :active, :boolean 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :account_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Session do
  #   # Found associations:
  #   # Found columns:
  #     configure :id, :integer 
  #     configure :session_id, :string 
  #     configure :data, :text 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model User do
  #   # Found associations:
  #     configure :account, :belongs_to_association 
  #     configure :domain, :belongs_to_association 
  #     configure :points, :has_many_association 
  #     configure :positions, :has_many_association 
  #     configure :inclusions, :has_many_association 
  #     configure :point_listings, :has_many_association 
  #     configure :point_similarities, :has_many_association 
  #     configure :comments, :has_many_association 
  #     configure :proposals, :has_many_association 
  #     configure :activities, :has_many_association   #   # Found columns:
  #     configure :id, :integer 
  #     configure :account_id, :integer         # Hidden 
  #     configure :unique_token, :string 
  #     configure :email, :string 
  #     configure :unconfirmed_email, :string 
  #     configure :password, :password         # Hidden 
  #     configure :password_confirmation, :password         # Hidden 
  #     configure :reset_password_token, :string         # Hidden 
  #     configure :remember_created_at, :datetime 
  #     configure :sign_in_count, :integer 
  #     configure :current_sign_in_at, :datetime 
  #     configure :last_sign_in_at, :datetime 
  #     configure :current_sign_in_ip, :string 
  #     configure :last_sign_in_ip, :string 
  #     configure :confirmation_token, :string 
  #     configure :confirmed_at, :datetime 
  #     configure :confirmation_sent_at, :datetime 
  #     configure :created_at, :datetime 
  #     configure :updated_at, :datetime 
  #     configure :sessions, :text 
  #     configure :admin, :boolean 
  #     configure :avatar_file_name, :string         # Hidden 
  #     configure :avatar_content_type, :string         # Hidden 
  #     configure :avatar_file_size, :integer         # Hidden 
  #     configure :avatar_updated_at, :datetime         # Hidden 
  #     configure :avatar, :paperclip 
  #     configure :avatar_remote_url, :string 
  #     configure :name, :string 
  #     configure :bio, :text 
  #     configure :url, :string 
  #     configure :facebook_uid, :string 
  #     configure :google_uid, :string 
  #     configure :yahoo_uid, :string 
  #     configure :openid_uid, :string 
  #     configure :twitter_uid, :string 
  #     configure :twitter_handle, :string 
  #     configure :registration_complete, :boolean 
  #     configure :domain_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
end
