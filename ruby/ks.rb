require 'httparty'

def check_availability(models, model)
	availability = models.select {|e| e['reference'] == model }.first
	available = availability['zones'].select {|e| e['availability'] != 'unavailable'}
	available.count
end

url = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2'

response = HTTParty.get(url)

models = {
	ks_1: '142sk9',
	ks_2: '142sk2',
	ks_3: '142sk3',
	ks_4: '142sk4'
}

availability = response['answer']['availability']

models.each { |_, reference| puts check_availability(availability, reference) }