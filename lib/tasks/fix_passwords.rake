task :fix_passwords => :environment do
  User.where("registered=1 and encrypted_password not like '$%'").each do |u|
    u.encrypted_password = BCrypt::Password.create(SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')[0,20])
    u.save
  end
end