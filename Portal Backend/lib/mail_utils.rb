class MailUtils
  def self.send_simple_message(subject, text)
    RestClient.post "https://api:key-#{ENV['MAILGUN_API_KEY']}"\
    "@api.mailgun.net/v3/#{ENV[MAILGUN_DOMAIN]}/messages",
    :from => "<noreply@core.instantcard.net>",
    :to => ENV[MAILGUN_SYSTEM_NOTIFICATION],
    :subject => subject,
    :text => text
  end
end
