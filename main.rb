require 'open-uri'
require 'tty-prompt'
require 'awesome_print'

require 'json'
require 'nokogiri'
require 'xml/to/hash'


parsers = {
	json: lambda {|raw| JSON.parse(raw)},
	html: lambda {|raw| Nokogiri::HTML(raw).to_hash }
}

prompt = TTY::Prompt.new

loop do
	mode = prompt.select("Explore with...", [:url, :data])
	parser = prompt.select("Using...", parsers.keys)
	parse = parsers.fetch(parser, lambda {|raw| raw})

	loop do 
		case mode
		when :url
			url = 'https://example.com' #prompt.ask('url:')
			raw = URI.open(url)
		when :data
			raw = prompt.multiline("#{parser}:").join
		end

		data = nil
		begin
			data = parse.call(raw)
		rescue
			prompt.error('Failed to parse data.')
			raise
			#next
		else
			prompt.ok('Parsed data.')
			ap data
		end
		break
	end
	break
end


#prompt.ask('Enter in a url')