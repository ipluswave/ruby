
# Create the master user
master_user = User.where(email: 'admin@instantcard.net').first
if master_user.nil?
  master_user = User.new(email: 'admin@instantcard.net', password: '1q2w3e4r', password_confirmation: '1q2w3e4r')
end

unless master_user.has_role? :master
  master_user.add_role :master
  master_user.save
end
