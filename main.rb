require 'open-uri'
require 'tty-prompt'

require 'json'
require 'nokogiri'

def parse_html(raw)
	def parse_nodes(nodes)
		nodes&.map do |node|
			{
				name: node.name,
				text: node.text,
				#attributes: node.attributes,
				children: parse_nodes(node.children)
			}
		end
	end

	return parse_nodes(Nokogiri::HTML(raw).css('*'))
end

parsers = {
	json: lambda {|raw| JSON.parse(raw)},
	html: lambda {|raw| parse_html(raw)}
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
			pp data
		end
		break
	end
	break
end


#prompt.ask('Enter in a url')