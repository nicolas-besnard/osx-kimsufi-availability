require 'observer'
require 'httparty'
require 'terminal-notifier'

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

class ModelCollection
	MODELS = {
		ks_1: '142sk9',
		ks_2: '142sk2',
		ks_3: '142sk3',
		ks_4: '142sk4',
		ks_5a: '142sk5',
		ks_5b: '142sk8',
		ks_6: '142sk6'
	}
end

class LastDelivery
	URL = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getElapsedTimeSinceLastDelivery'

	def check
		ModelCollection::MODELS.each do |model, reference|
			gamme = {gamme: reference}.to_json
			response = HTTParty.get(URL, query: { params: gamme })

			if time = response['answer']
				puts "#{model.to_s} : #{date_since_elapsed_time(time.to_i)}"
			end
		end
	end

	private

	def date_since_elapsed_time(time)
		Time.at(Time.now.to_i - time.to_i).strftime('%d/%m/%y - %H:%M')
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
c.add_observer(notifier)

c.do_

# ld = LastDelivery.new
# ld.check