# encoding: UTF-8

require 'selenium-webdriver'
require_relative 'order'
require_relative 'coffee'
#require_relative 'user'

def is_creditcard? card_num
	!!(card_num.to_s =~ (/^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})$/))
end

def login email, password
	wait = Selenium::WebDriver::Wait.new(:timeout => 10)

	url1 = @driver.current_url

	@driver.find_element(css: 'a.login').click

	email_field = wait.until{@driver.find_element id: 'edit-name'}
	pass_field = @driver.find_element id: 'edit-pass'
	submit_btn = @driver.find_element id: 'edit-submit'

	wait.until{email_field.displayed?}

	email_field.send_keys email
	pass_field.send_keys password
	submit_btn.click

	raise ArgumentError, "Wrong credentials" if url1 != @driver.current_url
end

def login_prompt
	puts "Before we can actually order anything, I'm gonna need you to login. Nespresso policy."

	begin 
		puts "What's your email?"
		print '~ '; email = gets.chomp
		puts
		puts "Good, good. Password?"
		print '~ '; password = gets.chomp
		puts
		puts "Great, let's see if this works..."
		login email, password
	rescue ArgumentError => e
		puts "Nope, wrong credentials. Try again?"
		puts
		print '~ '; input = gets.chomp
		if input =~ /(?:y|yes|yep|sure|okay|yeah|let's go|positive|affirmative)/i
			@driver.get @nespresso_order_url
			puts
			retry
		else
			teardown
		end
	end
	puts "All systems are a-go. Let's do this thing."
	puts
end

def checkout user
end

def coffee_options
	coffee_buttons = @driver.find_elements(css: '#node-16 > div.content > div > div > div > div > div.view-content > div > ul > li')
	coffee_tabs = []
	coffees = Order.new

	coffee_buttons.each do |coffee|
		@driver.action.key_down(:control).click(coffee).key_up(:control).perform #middle click
		coffee_tabs << 0
	end
	
	@driver.find_element(css: 'body').send_keys :control, '2'
	@driver.switch_to.default_content

	coffee_tabs.each_with_index do |coffee, i|
		c = Coffee.new

		name = @driver.find_element(css: 'h1:not(#site-logo)').text
		
		id = i+1

		intensity = @driver.find_element(css: 'div.intense_bar_num > span').text

		price = @driver.find_element(css: 'span.uc-price').text[1..-1]

		url = @driver.current_url

		c.name = name
		c.id = id
		c.intensity = intensity
		c.price = price
		c.url = url
		
		coffees.add c

		@driver.find_element(css: 'body').send_keys :control, 'w', '2'
		@driver.switch_to.default_content
	end

	return coffees
end

def save_default_order
	File::write 'default.order', @order.export
end

def load_default_order
	@order = Order.import File::read 'default.order'
end

def add_capsules amount, intensity
	puts 'add_capsules'
end

def add_capsules_with_url amount, url
	puts 'add_capsules_with_url'
end

def parser
	review_counter = 0
	help_text = "The list of commands is as follows:
	
	help ------------------------ Shows this helpful message.

	order <x> of intensity <y> -- Adds the selected capsules to the shopping cart,
	                              with as much variety at a low price as possible.
	                              (alt. 'o <x> <y>')
	order <x> of <url> ---------- Adds the selected capsule. (alt. o <x> <url>)
	remove <x> of <id> ---------- Removes the selected capsules from your order.
	                              You can review your order to get the id (alt.
	                              'r <x> <id>')

	review order ---------------- Shows your current order. (alt. review)
	checkout -------------------- Begins the checkout process.

	save default order ---------- Saves the current order as the default order.
	                              (alt. 'save')
	load default order ---------- Loads the default order. (alt. 'load')

	quit ------------------------ Exit without ordering (!)".gsub("\t", "")

	while true
		if review_counter > 0
			just_reviewed = true
		else
			just_reviewed = false
		end
		review_counter -= 1 unless review_counter == 0

		puts
		puts "======================================="
		puts "What would you like to order today?"
		puts "(type 'help' for help)"
		puts
		print "~ "; input = gets.chomp
		puts

		case input
		when /^h(?:elp)?$/i
			puts help_text
		when /^(?:'|")help(?:'|")$/i
			puts "You thought you could break me. You can't."
			puts "But I'll still be nice to you. Here, have some patronizing help."
			puts
			puts help_text
		
		when /^o(?:rder)? (.+)$/i
			case $1
			when /^(\d{1,2}) (?:of (?:intensity |power )?)?(\d{1,2})$/
				add_capsules($1, $2)
			when /^(\d{1,2}) (?:of )?(https:\/\/nespresso.co.il\/.*)$/
				add_capsules_with_url($1, $2)
			else
				puts "Sorry, I didn't quite catch that. Try again?"
			end
		when /^(?:rem(?:ove)?|d(?:el(?:ete)?)?)(\d+) (\d+)$/i
			@order.remove $1, $2

		when /^r(?:eview(?: order)?)?$/i
			puts @order.to_s
		when /^c(?:heckout)?$/i
			unless just_reviewed
				puts @order.to_s
				puts
				puts "Please take a moment to review your order. Are you sure everything is correct?"
				puts
				print '~ '; next unless !!(gets.chomp =~ /(?:y|yes|yep|sure|okay|yeah|let's go|positive|affirmative)/i)
			end

			break
		
		when /^s(?:ave)?(?:(?: )d(?:efault)?(?:(?: )o(?:rder)?)?)?$/i
			if @order.is_empty?
				puts "Your order is empty!"
				puts "You can review it with 'review order', though."
			elsif File.exist? 'default.order'
				puts "There's already a default order. Are you sure you want to overwrite it?"
				puts
				print '~ '; save_default_order if !!(gets.chomp =~ /(?:y|yes|yep|sure|okay|yeah|let's go|positive|affirmative)/i)
			else
				save_default_order
			end
		when /^l(?:oad)?((?:(?: )d(?:efault)?)?)?(?:(?: )o(?:rder)?)?$/i
			if !(File.exist? 'default.order')
				puts "You didn't save a default order yet, ya dingus."
				puts "(you can, though, by using 'save default order')"
			else
				@order = load_default_order
			end
		
		when /^(?:q|ex|exit|quit|bye|bai|nevermind|goodbye|good bye|cya|stop|(?:go )?away|(?:the )?end)$/i
			teardown
		
		when /^v(?:\?| is(?:\?| for)?\??)?$/i
			puts "V is for Vitalik. Don't you forget it."
		when /^run (.*)$/i
			eval $1
		else
			puts "Sorry, I didn't quite catch that. Try again?"
		end
	end
	puts
end

def setup
	puts "Setting everything up..."
	
	nespresso_order_url = 'https://nespresso.co.il/%D7%A2%D7%9E%D7%95%D7%93-%D7%9E%D7%A2%D7%A8%D7%9B%D7%AA/19-%D7%AA%D7%A2%D7%A8%D7%95%D7%91%D7%95%D7%AA-%D7%9E%D7%95%D7%A4%D7%9C%D7%90%D7%95%D7%AA'
	@order = Order.new
	
	@driver = Selenium::WebDriver.for :firefox
	@driver.get nespresso_order_url

	@coffees = coffee_options

	@driver.quit

	puts "Everything passed without a hitch. Wonderful."
	puts
end

def run
	puts
	puts 'Welcome to automated coffee ordering magic goodness!'
	puts
	puts 'In order to see capsule names, which are in Hebrew, your console must'+
	  ' use a TrueType font like Courier New.'
	puts

	if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
		print "If you're on a Windows machine, here's a handy guide for installing"+
		  ' a TrueType font in CMD: '
		puts 'https://web.archive.org/web/20140801012905/http://caspit.blogspot.co.il/2012/07/command-line-cmd.html'
		puts
	end
	
	setup
	
	parser

	login_prompt

	puts 'checkout'
end

def teardown
	@driver.quit unless @driver.to_s.include? 'null'
	exit
end

#run