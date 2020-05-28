#!/usr/bin/env ruby

require 'nagios'
require 'time'
require 'open-uri'
require 'yajl'
require 'set'
require 'resolv'

module Memory
  def memory(m)
    (100.0 * m[:memory][:usedMemory] / m[:memory][:totalMemory]).round
  end

  def warning(m)
    memory(m) > threshold(:warning)
  end

  def critical(m)
    memory(m) > threshold(:critical)
  end

  def to_s(m)
    "#{memory(m)}%"
  end
end

module Intervals
  def ranges(m)
    @ranges ||= m.map do |segment|
      _, interval_start, interval_end = segment.split("_")
      (DateTime.parse(interval_start).to_time.to_i ... DateTime.parse(interval_end).to_time.to_i)
    end
  end

  def gaps(m)
    gaps = SortedSet.new
    min = (Date.today - 60).to_time.to_i

    ranges(m).each do |range|
      min = [min, range.min].min
    end

    min.step(Time.now.to_i, 3600).each do |hour|
      next if @whitelist.include?(hour)
      next if ranges(m).any? { |range| range.include?(hour) }

      gaps << Time.at(hour).utc
    end

    gaps
  end

  def critical(m)
    gaps(m).any?
  end

  def to_s(m)
    if gaps(m).any?
      "missing intervals: #{gaps(m).inspect}"
    else
      "no missing intervals"
    end
  end
end

module LoadQueue
  def load_queue(m)
    Hash[m.map { |node, stats| [node.to_s.split(':').first, stats[:segmentsToLoad]] }]
  end

  def warning(m)
    load_queue(m).values.any? do |value|
      value > threshold(:warning)
    end
  end

  def critical(m)
    load_queue(m).values.any? do |value|
      value > threshold(:critical)
    end
  end

  def to_s(m)
    load_queue(m).select do |node, value|
      value > threshold(:warning)
    end.map do |node, value|
      "#{node}: #{value}"
    end.sort.join(', ')
  end
end


Class.new(Nagios::Plugin) do
  def initialize
    super

    @nodes = []
    @homedir = "/var/app/druid"
    @whitelist = Set.new

    @config.options.on('-m', '--mode=MODE',
      'Mode to use (pubsub, ad_provider_times, ...)') { |mode| @mode = mode }
    @config.options.on('-u', '--url=URL',
      'Which URL to query for stats') { |url| @url = url}
    @config.options.on('-n', '--nodes=NODE,NODE,...',
      'Which URL to query for stats') { |node| @nodes << node }
    @config.options.on('-D', '--homedir=DIR',
      'Kafka Home Directory') { |homedir| @homedir = homedir }
    @config.options.on('-W', '--whitelist=TS,TS,TS,...',
      'Which Segments to whitelist in check') {|whitelist| whitelist.split(',').each {|w| @whitelist << Time.parse(w).to_i } }

    @config.parse!
    raise "No mode given" unless @mode

    self.extend(Object.const_get(@mode.to_sym))
  end

  def warning(m)
    false
  end

  def parse(json)
    Yajl::Parser.new(:symbolize_keys => true).parse(json)
  end

  def measure
    @stats ||= parse(open(@url))
  end
end.run!
