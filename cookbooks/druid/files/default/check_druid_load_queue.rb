#!/usr/bin/env ruby

require 'nagios'
require 'json'


Class.new(Nagios::Plugin) do
  def initialize
    super
    @config.options.on('-u', '--unit=UNIT',
      'systemd unit to check') { |unit| @unit = unit }

    @config.parse!
    raise "No unit given" unless @unit
  end

  def warning(m)
    false
  end

  def critical(m)
    m.length > 0
  end

  def to_s(m)
    if m.length == 0
      "so far so good"
    else
      "#{m.join(",")} look stuck loading segments, restart?"
    end
  end

  def measure
    %x{journalctl --since -3min --until now -u #{@unit} |grep "queue stuck"}.scan(/ON (.+?),/).flatten.uniq
  end
end.run!
