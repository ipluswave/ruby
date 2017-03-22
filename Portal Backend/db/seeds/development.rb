
# Create the master user
master_user = User.where(email: 'system@instantcard.net').first
if master_user.nil?
  master_user = User.new(email: 'system@instantcard.net', password: 'changeme', password_confirmation: 'changeme')
end

unless master_user.has_role? :master
  master_user.add_role :master
  master_user.save
end
