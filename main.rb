require 'open-uri'
require 'tty-prompt'
require 'tty-tree'
require 'awesome_print'

require 'json'
require 'nokogiri'
require 'xml/to/hash'


parsers = {
	json: lambda {|raw| JSON.parse(raw)},
	html: lambda {|raw| Nokogiri::HTML(raw).to_hash}
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
			url = "https://example.com"#prompt.ask('url:')
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

	prompt.keypress("Press any key to continue, resuming in :countdown...", timeout: 3)
	system 'clear'

	# explore data
	# TODO: sanitize strings in html content with str.dump

	stack = []
	curr = data

	loop do
		nodes = []
		context = curr.class
		if context == Array
			nodes = curr
		elsif context == Hash
			nodes = curr.keys
		end

		header = "Level #{stack.length} - #{context}"

		leaf = nodes.empty?
		root = stack.empty?
		opts = []
		opts << :select unless leaf
		opts << :back unless root
		opts << :menu

		action = prompt.select("#{header} | Node", opts)
		system 'clear'

		case action
		when :select
			node = prompt.select("#{header} | Select", nodes)
			system 'clear'
			stack.push curr
			curr = node
		when :back
			curr = stack.pop
		when :menu
			commands = [:resume, :new, :exit]
			command = prompt.select("#{header} | Menu", commands)
			system 'clear'

			case command
			when :resume
				next
			when :new
				break
			when :exit
				exit
			end
		end
	end
end
