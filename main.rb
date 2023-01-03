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
			index = 0
			nodes = curr.map do |elem|
				index += 1
				{
					name: "#{index} - #{elem&.class}",
					value: elem
				}
			end
		elsif context == Hash
			nodes = curr.to_a.map do |key, value|
				{
					name: "#{key} - #{value&.class}",
					value: value
				}
			end
		end

		header = "Level #{stack.length} - #{context}"

		leaf = nodes.empty?
		root = stack.empty?
		opts = []
		opts << :select unless leaf
		opts << :back unless root
		opts << :menu

		action = prompt.select("#{header} | Node", opts, cycle: true)
		system 'clear'

		case action
		when :select
			node = prompt.select("#{header} | Select", nodes, cycle: true, per_page: 10)
			system 'clear'

			if [Array, Hash].include? node.class
				stack.push curr
				curr = node
			else
				prompt.say("#{header} | Select -> #{node.class}")
				ap node
				prompt.keypress("Press any key to continue...")
				system 'clear'
			end
		when :back
			curr = stack.pop
		when :menu
			commands = [:continue, :load, :exit]
			command = prompt.select("#{header} | Menu", commands)
			system 'clear'

			case command
			when :continue
				next
			when :load
				break
			when :exit
				exit
			end
		end
	end
end
