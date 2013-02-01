# Warden::Manager.after_authentication :except => :fetch do |record, warden, options|
#   record.sessions ||= ''
#   record.sessions =  record.sessions.split(',').push(warden.env['rack.session.record'].id).join(',')
#   record.save
# end

class Array
  def comprehend(&block)
    return self if block.nil?
    self.collect(&block).compact
  end
end