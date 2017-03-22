# Steps to run Print Production environment

1. Create .env file with Print Production environment variables
2. Execute the command below
	$ RAILS_ENV=print foreman start -e .env.print -f Procfile.print -c worker=1

# Running it locally with Web and Preview servers
foreman start -f Procfile.local -e .env.devevelopment -c web=1,web-p=1

# Running it locally to print jobs
foreman start -f Procfile.local -c worker=1

# Run Heroku on background
heroku run:detached rake db:migrate --app=instantcard

