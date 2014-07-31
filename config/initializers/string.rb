# http://apidock.com/rails/ActionView/Helpers/SanitizeHelper/sanitize
class String
  def sanitize(options={})
    ActionController::Base.helpers.sanitize(self, options)
  end
end
