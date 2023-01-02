require 'open-uri'
require 'tty-prompt'

require 'json'
require 'nokogiri'

parsers = {
	json: lambda {|raw| JSON.parse(raw)},
	html: lambda {|raw| Nokogiri::HTML(raw)}
}


prompt = TTY::Prompt.new

loop do
	mode = prompt.select("Explore with...", [:url, :data])
	parser = prompt.select("Using...", parsers.keys)
	parse = parsers.fetch(parser, lambda {|raw| raw})

	loop do 
		case mode
		when :url
			url = prompt.ask('url:')
			raw = URI.open(url)
		when :data
			raw = prompt.multiline("#{parser}:").join
		end

		data = nil
		begin
			data = parse.call(raw)
		rescue
			prompt.error('Failed to parse data.')
			next
		else
			prompt.ok('Parsed data.')
			pp data
		end

	end
end


#prompt.ask('Enter in a url')