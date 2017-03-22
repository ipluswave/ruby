
# By default Capybara will try to boot a rack application
# automatically. You might want to switch off Capybara's
# rack server if you are running against a remote application
Capybara.run_server = false
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    # Raise JavaScript errors to Ruby
    js_errors: false,
    # Additional command line options for PhantomJS
    phantomjs_options: ['--ignore-ssl-errors=yes'],
    timeout: 300
  })
end
Capybara.current_driver = :poltergeist
