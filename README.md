# data-explorer

A command-line interface for viewing and navigating nested data structures. Import data from a url, or type in / paste in data yourself. Features a select menu and a pager.

## Installation

Clone the repository:
```shell
git clone https://github.com/johnryanmal/data-explorer ~/data-explorer
```

Alias the command in your [rc file](https://en.wikipedia.org/wiki/Configuration_file):

`.zshrc`
```shell
echo 'alias cli-data-explorer="ruby ~/data-explorer/main.rb"' >> ~/.zshrc
```

After restarting your shell, you can now use the command:
```shell
cli-data-explorer
```

## Updating

Pull from the repository:
```
git -C ~/data-explorer pull origin main
```
