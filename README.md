#!/usr/bin/env ruby

### Pinspiral
A bot for pinspire.com

```ruby
require './pinspiral.rb'

username = 'user@email.com'
password = 'password'

bot = Pinspiral::PinspireBot.new(username, password)

puts "Logging in with account #{username}\n"

if bot.login
	#
	# You can also use bot.signed_in? after logins complete
	#
	puts 'Logged in!'	
	bot.set_board('http://www.pinspire.com/location/board_title')
	img = 'https://a248.e.akamai.net/assets.github.com/images/modules/about_page/github_logo.png?1315937507'
	bot.pin('http://github.com/runexec', 'Github', img)
else
	puts "Failed to login with #{bot}\n"
end
```
