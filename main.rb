require 'bundler/inline'

puts "Loading..."
gemfile do
	source "https://rubygems.org"
	
	gem 'open-uri'
	gem 'tty-prompt'
	gem 'tty-pager'
	gem 'awesome_print'

	gem 'json'
	gem 'yaml'
	gem 'nokogiri'
	gem 'xml-to-hash'
end
system 'clear'


def options(array)
	return array.map do |value|
		{
			name: value,
			value: value
		}
	end
end

def choices(array)
	index = 0
	return array.map do |option|
		index += 1
		next option.merge({value: [option[:value], index]})
	end
end


parsers = {
	json: lambda {|raw| JSON.parse(raw)},
	yaml: lambda {|raw| YAML.load(raw)},
	html: lambda {|raw| Nokogiri::HTML(raw).to_hash}
}

prompt = TTY::Prompt.new
pager = TTY::Pager.new

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

	prompt.keypress("Press any key to continue, resuming in :countdown...", timeout: 3)
	system 'clear'

	# explore data
	# TODO: sanitize strings in html content with str.dump (solving with awesome_print's #ai)

	stack = []
	curr = data
	action_cursor = 1
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
		node_opts = choices(nodes)

		header = "Level #{stack.length} - #{context}"

		leaf = nodes.empty?
		root = stack.empty?
		actions = []
		actions << :select unless leaf
		actions << :view
		actions << :back unless root
		actions << :menu
		action_opts = choices(options(actions))

		action, action_cursor = prompt.select("#{header} | Node", action_opts, default: action_cursor, cycle: true)
		system 'clear'

		case action
		when :view
			pager.page(curr.ai)
		when :select
			select_cursor = 1
			loop do
				node, select_cursor = prompt.select("#{header} | Select", node_opts, default: select_cursor, cycle: true, per_page: 10)
				system 'clear'

				view = (node.class == String)? node : node.ai
				lines = view.split("\n")
				line_limit = 10
				truncated = (lines.length > line_limit)
				if truncated
					summary = [*lines[0...line_limit], "(use view to see #{lines.length - line_limit} more lines)"].join("\n")
				else
					summary = view
				end

				commands = []
				commands << :unselect
				commands << :select if [Array, Hash].include? node.class
				commands << :view if truncated
				commands << :back
				command_opts = choices(options(commands))
				command = nil

				view_cursor = 1
				loop do
					prompt.say("#{header} | Select -> #{node.class}")
					prompt.say("===\n")
					prompt.say(summary)
					prompt.say("===\n")

					command, view_cursor = prompt.select('Continue?', command_opts, default: view_cursor, cycle: true)
					system 'clear'

					if command == :view
						pager.page(view)
					else
						break
					end
				end

				case command
				when :unselect
					next
				when :select
					stack.push curr
					curr = node
					break
				when :back
					break
				end
			end
		when :back
			curr = stack.pop
		when :menu
			commands = [:continue, :load, :exit]
			command = prompt.select("#{header} | Menu", commands, cycle: true)
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
