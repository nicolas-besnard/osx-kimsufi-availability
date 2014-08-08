require 'httparty'
require 'json'
require 'terminal-notifier'

require './model_collection.rb'

class LastDelivery
	URL = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getElapsedTimeSinceLastDelivery'

	attr_accessor	:last_availability

	def initialize
		self.last_availability = {}
		ModelCollection::MODELS.each do |model, reference|
			self.last_availability[model] = 0
		end

		ModelCollection::MODELS.each do |model, reference|
			gamme = {gamme: reference}.to_json
			response = HTTParty.get(URL, query: { params: gamme })

			if time = response['answer']
				self.last_availability[model] = time.to_i
			end
		end
	end

	def check
		ModelCollection::MODELS.each do |model, reference|
			gamme = {gamme: reference}.to_json

			begin
				response = HTTParty.get(URL, query: { params: gamme })
			rescue Errno::ECONNREFUSED => e
				puts "  -- Request TimeOut #{e.inspect}"
				sleep 15
				next
			end

			if time = response['answer']
				if time.to_i < self.last_availability[model]
					TerminalNotifier.notify("Last Delivery - Server Now Available #{model}", title: 'Kimsufi', open: 'https://www.kimsufi.com/fr/index.xml')
					puts "CHANGE FOR #{model}"
				else
					puts "[#{Time.now}] No #{model} available :( #{time}"
				end
				self.last_availability[model] = time.to_i
			else
				puts "error"
			end
		end
	end

	private

	def date_since_elapsed_time(time)
		Time.at(Time.now.to_i - time.to_i).strftime('%d/%m/%y - %H:%M')
	end

end

ld = LastDelivery.new
loop do
	ld.check
	sleep 15
end