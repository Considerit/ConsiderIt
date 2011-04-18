Warden::Manager.after_authentication :except => :fetch do |record, warden, options|
  #require 'pp'
  #pp(warden.env['rack.session.record'])
  record.sessions ||= ''
  record.sessions =  record.sessions.split(',').push(warden.env['rack.session.record'].id).join(',')
  record.save
end