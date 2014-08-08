require 'observer'
require 'httparty'
require 'terminal-notifier'
require 'dotenv'
require 'twitter'

require './model_collection.rb'

Dotenv.load

class TweetNotifier

	def update(now_available, now_sold_out)
		if !now_available.empty?
			puts "  -- Now Available #{now_available}"
			init_client.update("Now Available #{now_available} #kimsufi")
		end

		if !now_sold_out.empty?
			puts "  -- Now Sold Out #{now_sold_out}"
			init_client.update("Sold Out #{now_sold_out} #kimsufi")
			TerminalNotifier.notify("Server Sold Out #{now_sold_out}", title: 'Kimsufi', open: 'https://www.kimsufi.com/fr/index.xml')
		end
	end

	def init_client

		Twitter::REST::Client.new do |config|
			config.consumer_key        = ENV['CONSUMER_KEY']
			config.consumer_secret     = ENV['CONSUMER_SECRET']
			config.access_token        = ENV['ACCESS_TOKEN']
			config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
		end

	end

end

class Notifier
	def update(now_available, now_sold_out)
		if !now_available.empty?
			puts "  -- Now Available #{now_available}"
			TerminalNotifier.notify("Server Now Available #{now_available}", title: 'Kimsufi', open: 'https://www.kimsufi.com/fr/index.xml')
		end

		if !now_sold_out.empty?
			puts "  -- Now Sold Out #{now_sold_out}"
			TerminalNotifier.notify("Server Sold Out #{now_sold_out}", title: 'Kimsufi', open: 'https://www.kimsufi.com/fr/index.xml')
		end
	end
end


class Checker
	include Observable

	URL = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2'


	def initialize
		init_instance_variable
	end

	def do_
		now_available = []
		now_sold_out = []

		loop do
			begin
				response = HTTParty.get(URL, timeout: 20)
			rescue Errno::ECONNREFUSED => e
				puts "  -- Request TimeOut #{e.inspect}"
				next
			rescue
				next
			end

			ModelCollection::MODELS.each do |model, reference|

				begin
					count = check_availability(response['answer']['availability'], reference)
				rescue
					break
				end

				if instance_variable_get("@#{model.to_s}") != count
					if count == 0
						now_sold_out << model.to_s
					else
						now_available << model.to_s
					end

					instance_variable_set("@#{model.to_s}", count)
				end
			end

			if now_available.empty? && now_sold_out.empty?
				puts "[#{Time.now}] No New Server :("
			else !now_available.empty? || !now_sold_out.empty?
				changed
				notify_observers(now_available, now_sold_out)
				now_available.clear
				now_sold_out.clear
			end

			sleep 10

		end
	end

	private

	def init_instance_variable
		response = HTTParty.get(URL)
		ModelCollection::MODELS.each do |model, reference|
			count = check_availability(response['answer']['availability'], reference)
			instance_variable_set("@#{model.to_s}", count)
		end
	end

	def check_availability(resources, model)
		availability = resources.select {|e| e['reference'] == model}.first
		available = availability['zones'].select {|e| e['availability'] != 'unavailable'}
		available.count
	end

end

c = Checker.new
notifier = Notifier.new
tweet_notifier = TweetNotifier.new
c.add_observer(notifier)
c.add_observer(tweet_notifier)

c.do_



# ld = LastDelivery.new
# ld.check