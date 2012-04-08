#!/usr/bin/env ruby

=begin 
## Copyright (c) 2012 Ryan Kelker and individual contributors.
## ( https://github.com/runexec/Pinspiral ) Pinspiral
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 1. Redistributions of source code must retain the above copyright
## notice, this list of conditions and the following disclaimer
## in this position and unchanged.
## 2. Redistributions in binary form must reproduce the above copyright
## notice, this list of conditions and the following disclaimer in the
## documentation and/or other materials provided with the distribution.
## 3. The name of the author may not be used to endorse or promote products
## derived from this software withough specific prior written permission
##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
## IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
## OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
## IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
## INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
## NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES# LOSS OF USE,
## DATA, OR PROFITS# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
## THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
## THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end

module Pinspiral

	require 'mechanize'
	require 'base64'

	class PinspireBot

		LOGIN_PAGE = 'http://www.pinspire.com/login'
		PIN_PAGE = 'http://www.pinspire.com/pin/doCreate'

		BROWSERS= {
			firefox: 'Mozilla/5.0 (X11;Linux x86_64;rv:11.0) Gecko/20100101'
		}

		def initialize(username, password, user_agent = nil)
			@username = username
			@password = password
			@agent = Mechanize.new
			@user_agent = user_agent
			@agent.user_agent=(@user_agent ||= BROWSERS.first)
			@ua = @agent.user_agent
			@cookie_jar = @agent.cookie_jar
			@pins = []
			@search_log = []
			@signed_in = false
			@user_id = 0
			@current_board = ''
			@current_board_id = 0
		end

		def to_s; "Browser: #{@ua} \nAccount: #{@username} : #{@password}"; end

		def signed_in?; @signed_in.eql? true; end

		def get_username; @username; end

		def get_userid; @user_id; end

		def clear_cookies
			@agent.cookie_jar = Mechanize.new.cookie_jar
			@cookie_jar = @agent.cookie_jar
		end

		def get_cookies; @agent.cookies(); end

		def show_pins; self.get_pins.each { |pin| puts pin }; end
		
		def login
			# Get login page to set valid cookies
			form = self.get_login_form
			# be nice about it
			sleep(5)

			page = post_page(LOGIN_PAGE, {
				email: @username,
				password: @password
			})

			@user_id = page.body.split(',"id":')[1].split(',')[0].to_i

			self.get_cookies.each { |cookie|
				(key, _) = cookie.to_s.split('=')
				if (key.downcase == 'remember_me_cookie') and @user_id > 0
					@signed_in = true
					return true
				end
			}
			false
		end
		
		def set_board(board_url)
			url = board_url

			puts 'Getting board from ' + url
			
			@current_board = url
			html = self.get_page(url).body
			id = html.split('"pinboard_boardid" value="')[1].split('"')[0]
			@current_board_id = id.to_i
			
			if @current_board_id > 0
				puts 'Found board id: ' + id
				true
			else
				puts 'Failed to find board id'
				false
			end
		end

		def pin(url, description, img_url)
			@pins.push [@current_board, url, description, img_url]
			puts 'Attempting to pin ' + @pins.last.join("\n")

			# all submitting urls must be a Base64 Encoded
			url = Base64.encode64(url).chop.chop
			img_url = Base64.encode64(img_url).chop.chop
			ref = 'http://www.pinspire.com/pin/pinIt/'
			page = self.post_page(PIN_PAGE, {
				'board.id' => @current_board_id,
				'user.id' => @user_id,
				imgWebUrl: img_url,
				source: 'web',
				prefix: 'pi',
				uploadMethod: 'PinButton',
				url: url,
				title: description
			}, { 'Referer' => ref, 'X-Request-With' => 'XMLHttpRequest'})
			page
		end
		

		def get_pins
			ret = []
			@pins.each { |board, url, desc, img| 
				count ||= 0
				count += 1
				display = [board, url, desc, img].join("\n\t")
				ret.push "Pin #{count}:\n\t#{display}"
			}
			ret
		end

		#
		# get_page(url)
		# post_page(url, values_hash) 
		#
		# Mechanized pages are returned
		#
		def get_page(url)
			 self.http_get_request(url)
		end

		def post_page(url, values_hash, headers = {})
			self.http_post_request(url, values_hash, headers)
		end

		def http_get_request(url)
			@agent.cookie_jar = @cookie_jar
			page = @agent.get(url)
			@cookie_jar = @agent.cookie_jar
			page
		end
		
		def http_post_request(url, values_hash, headers = {})
			@agent.cookie_jar = @cookie_jar
			page = @agent.post(url, values_hash, headers)
			@cookie_jar = @agent.cookie_jar
			page
		end

		def get_login_page
			self.get_page(LOGIN_PAGE)	
		end
		
		#	
		# get_login_form
		#
		# Returns Mechanized form of Pinspirebot
		#
		def get_login_form
			login_form = nil
			self.get_login_page.forms.each { |f| 
				if f.name.nil? then; next; end
				if f.name.eql? 'loginform'
					login_form = f
					break
				end
			}
			login_form
		end
	end
end

