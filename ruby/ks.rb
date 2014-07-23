class Checker

	URL = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2'
	MODELS = {
		ks_1: '142sk9',
		ks_2: '142sk2',
		ks_3: '142sk3',
		ks_4: '142sk4'
	}

	def initialize
		init_instance_variable
		do_
	end

	def do_
		now_available = []
		now_sold_out = []

		loop do
			response = HTTParty.get(URL)

			MODELS.each do |model, reference|

				count = check_availability(response['answer']['availability'], reference)

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
			end

			if !now_available.empty?
				puts "Now Available #{now_available}"
				now_available.clear
			end

			if !now_sold_out.empty?
				puts "Now Sold Out #{now_sold_out}"
				now_sold_out.clear
			end

			sleep 10

		end
	end

	private

	def init_instance_variable
		response = HTTParty.get(URL)
		MODELS.each do |model, reference|
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