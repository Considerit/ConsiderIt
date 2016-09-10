# http://apidock.com/rails/ActionView/Helpers/SanitizeHelper/sanitize
class String
  def sanitize(options={})
    sanitize_helper(self, options)
  end
end
