# # RailsAdmin config file. Generated on September 15, 2012 18:44
# # See github.com/sferik/rails_admin for more informations

# RailsAdmin.config do |config|

#   # If your default_local is different from :en, uncomment the following 2 lines and set your default locale here:
#   # require 'i18n'
#   # I18n.default_locale = :de

#   config.current_user_method { current_user } # auto-generated

#   # If you want to track changes on your models:
#   # config.audit_with :history, User

#   # Or with a PaperTrail: (you need to install it first)
#   config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0


#   # Set the admin name here (optional second array element will appear in a beautiful RailsAdmin red ©)
#   config.main_app_name = ['ConsiderIt', 'Admin']
#   # or for a dynamic name:
#   # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

#   config.authorize_with :cancan

#   #  ==> Global show view settings
#   # Display empty fields in show views
#   # config.compact_show_view = false

#   #  ==> Global list view settings
#   # Number of default rows per-page:
#   # config.default_items_per_page = 20

#   #  ==> Included models
#   # Add all excluded models here:
#   # config.excluded_models = [Account, Activity, ActsAsFollowable::Follow, Comment, DelayedMailhopper::Email, Domain, DomainMap, Inclusion, Mailhopper::Email, Point, PointListing, Opinion, Proposal, Reflect::ReflectBullet, Reflect::ReflectBulletRevision, Reflect::ReflectHighlight, Reflect::ReflectResponse, Reflect::ReflectResponseRevision, Session, User]

#   # Add models here if you want to go 'whitelist mode':
#   # config.included_models = [Account, Activity, ActsAsFollowable::Follow, Comment, DelayedMailhopper::Email, Domain, DomainMap, Inclusion, Mailhopper::Email, Point, PointListing, Opinion, Proposal, Reflect::ReflectBullet, Reflect::ReflectBulletRevision, Reflect::ReflectHighlight, Reflect::ReflectResponse, Reflect::ReflectResponseRevision, Session, User]

#   # Application wide tried label methods for models' instances
#   # config.label_methods << :description # Default is [:name, :title]

#   #  ==> Global models configuration
#   # config.models do
#   #   # Configuration here will affect all included models in all scopes, handle with care!
#   #
#   #   list do
#   #     # Configuration here will affect all included models in list sections (same for show, export, edit, update, create)
#   #
#   #     fields_of_type :date do
#   #       # Configuration here will affect all date fields, in the list section, for all included models. See README for a comprehensive type list.
#   #     end
#   #   end
#   # end
#   #

#   classes = ['Activity', 'Inclusion', 'Point', 'PointListing', 'Opinion', 'Proposal', 'User', 'Comment', 'Thank', 'Moderation', 'Assessable::Claim', 'Assessable::Request', 'Assessable::Assessment', 'Assessable::Verdict']
  
#   classes.each do |cls|
#     config.model cls do
#       edit do
#         #pp cls
#         exclude_fields :account_id, :account
#       end
#     end
#   end

#   config.model 'Proposal' do
#     edit do
#       exclude_fields :claims, :account_id, :account
#     end
#   end

#   #  ==> Model specific configuration
#   # Keep in mind that *all* configuration blocks are optional.
#   # RailsAdmin will try his best to provide the best defaults for each section, for each field.
#   # Try to override as few things as possible, in the most generic way. Try to avoid setting labels for models and attributes, use ActiveRecord I18n API instead.
#   # Less code is better code!
#   # config.model MyModel do
#   #   # Cross-section field configuration
#   #   object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
#   #   label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
#   #   label_plural 'My models'      # Same, plural
#   #   weight -1                     # Navigation priority. Bigger is higher.
#   #   parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
#   #   navigation_label              # Sets dropdown entry's name in navigation. Only for parents!
#   #   # Section specific configuration:
#   #   list do
#   #     filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
#   #     items_per_page 100    # Override default_items_per_page
#   #     sort_by :id           # Sort column (default is primary key)
#   #     sort_reverse true     # Sort direction (default is true for primary key, last created first)
#   #     # Here goes the fields configuration for the list view
#   #   end
#   # end

# end
