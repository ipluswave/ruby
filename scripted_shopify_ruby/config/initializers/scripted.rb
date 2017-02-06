require 'scripted_client'
ShopifyApp.configure do |config|
  ScriptedClient.organization_key = '57d77eda'
  ScriptedClient.access_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoyLCJwYXJ0eV9rZXkiOiIzODQ4NTc3ZCIsImV4cCI6MTU0NjkwNjgyMCwibG9uZ19saXZlZCI6dHJ1ZSwiaWF0IjoxNDUyMjEyNDIwfQ.vWuT7YK_Rt1k3g4JbjCl-XPPUcVu8Tn117eaqQkfQsQ'
end
# # First, find a JobTemplate that you'd like to use:
#
#    templates = ScriptedClient::JobTemplate.all
#    blog_post = templates.find { |template| template.name == 'Standard Blog Post' }
# #
# # # Next, assign some values for the Prompts on that JobTemplate.
# #
#    key_points = blog_post.prompts.find { |prompt| prompt.label == 'Key Points' }
#    key_points.value = ['Orangutans make great pets', 'Normal pets are lame']
# #
# # # Next, you can find an Industry:
# #
#    industries = ScriptedClient::Industry.all
#    lifestyle = industries.find { |industry| industry.name == 'Lifestyle & Travel' }
# #
# # # Now you can create the Job!
# #
#    job = ScriptedClient::Job.new(
#        topic: 'Top 10 Reasons to Buy an Orangutan',
#        job_template: blog_post,
#        industries: [lifestyle]
#    )
#    job.save
# #
#    ScriptedClient::Job.all
#    ScriptedClient::Job.draft_ready
# #
#    ScriptedClient::Job.find('5ceb8bb8235bcc76bf475e21')
# #
#    ScriptedClient::Job.find('5ceb8bb8235bcc76bf475e21').html_contents
# end
