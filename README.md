# Sticky Elephant

Sticky Elephant is a [medium-interaction](https://pdfs.semanticscholar.org/9d46/8fa983b844c76a07b1e3ea63d6f7a9cae294.pdf)
PostgreSQL honeypot.

```
sticky_elephant [options]
    -c, --config CONFIG              Configuration file to read
    -h, --help                       Display this screen
```

## Usage

Either install the gem and
```
% sticky_elephant
```

or clone the repo and

```
% ./bin/sticky_elephant
```

## Configuration
`sticky_elephant.conf` is a YAML file that defines Sticky Elephant's behavior.
You can tell Sticky Elephant what configuration file to use with `-c`.  The
configuration file looks like this:

```
:log_path: "./sticky_elephant.log"
:port: 5432
:host: 0.0.0.0
:debug: true
:abort_on_exception: false
:use_hpf: true
:hpf_host: 127.0.0.1
:hpf_port: 10000
:hpf_ident: 24b6875e-03f1-4c2a-b5b0-11af1f49e2bb
:hpf_secret: woofwoofcharlesisagooddog
```
`host` and `port` define the host address and port to which Sticky Elephant
should bind.  `log_path` is the log to which Sticky Elephant will write.  Do
note that HPFeeds logs go to `stdout` and are separate from Sticky Elephant
application logs.  `debug` turns on debug-level logging; `abort_on_exception`
kills threads when they encounter an exception.  The `hpf`-prefixed options are
for configuring the HPFeeds server to which Sticky Elephant should report
queries and connections.

## Installation

You can just run sticky_elephant in a tmux session, that certainly works. If you
prefer to set things up a bit nicer, make a `sticky_elephant` user and give them
a home directory.  Put your config file in
`/etc/sticky_elephant/sticky_elephant.conf` and ensure that the
`sticky_elephant` user can read it.  Then you can use this systemd service
definition to run sticky_elephant at boot:
```
[Unit]
Description=sticky_elephant postgres honeypot
Documentation=https://github.com/ffleming/sticky_elephant
After=network.target

[Service]
WorkingDirectory=/home/sticky_elephant/
User=sticky_elephant
ExecStart=/usr/local/bin/sticky_elephant -c /etc/sticky_elephant/sticky_elephant.conf
SyslogIdentifier=sticky_elephant
StandardOutput=syslog
StandardError=syslog
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
KillMode=process

[Install]
WantedBy=default.target
Alias=sticky_elephant.service
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/betheroot/sticky_elephant.

## To do
* Support [md5 authentication](https://www.postgresql.org/docs/9.6/static/auth-methods.html)
* Anti-fingerprinting
    * Mimic commands
        * `\l`
        * `\d`
        * `\dt`
* Log user-selected database in handshake
* Remove argument to `Payload#to_s`
* Break up `Payload` into separate objects
