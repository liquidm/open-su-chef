#!/usr/bin/env ruby

require 'nagios'
require 'json'
require 'open-uri'
require 'yajl'

Class.new(Nagios::Plugin) do
  def initialize
    super

    @config.options.on('-u', '--url=URL', 'Druid coordinator endpoint url') { |u| @url = u }
    @config.options.on('-d', '--datasource=DATASOURCE', 'Druid datasource') { |d| @datasource = d }
    @config.options.on('-w', '--warning=WARNING', 'Warning threshold') { |w| @warning = w.to_f }
    @config.options.on('-c', '--critical=CRITICAL', 'Critical threshold') { |c| @critical = c.to_f }

    @config.parse!

    missing = %w{url datasource warning critical}.select do |param|
      instance_variable_get("@#{param}").nil?
    end

    if missing.any?
      raise "Parameter(s) missing: #{missing.join(', ')}"
    end
  end

  def warning(m)
    !m || m < @warning
  end

  def critical(m)
    !m || m < @critical
  end

  def to_s(m)
    "Load status of #{@datasource} datasource: " + (m ? m.to_s : "unknown")
  end

  def measure
    return @load_status if @load_status

    raw_stats = open(@url)
    stats = Yajl::Parser.new.parse(raw_stats)

    @load_status = stats[@datasource]
  end

end.run!
