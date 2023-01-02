require 'open-uri'
require 'tty-prompt'
require 'tty-tree'
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
	data = nil

	# load data
	loop do 
		case mode
		when :url
			url = prompt.ask('url:')
			begin
				raw = URI.open(url)
			rescue
				prompt.error('Failed to access link.')
				next
			else
				prompt.ok('Accessed link.')
			end
		when :data
			raw = prompt.multiline("#{parser}:").join
		end

		begin
			data = parse.call(raw)
		rescue
			prompt.error('Failed to parse data.')
			#raise
			next
		else
			prompt.ok('Parsed data.')
			break
		end
	end

	# explore data
	# TODO: make this
	# TODO: sanitize strings in html content with str.dump
	# TODO: display top level data, hide lower levels
	ap data

	#test = {a:1,b:2,c:3}
	puts TTY::Tree.new(data).render

	break
end


#prompt.ask('Enter in a url')