#!/usr/bin/env ruby

require 'nagios'
require 'json'
require 'stringio'
require 'zk'
require 'zlib'
require 'time'
require 'yaml'

class CheckDruidSegments < Nagios::Plugin
  def initialize
    super

    @config.options.on('-z', '--zookeeper=ZOOKEEPER',
      'Zookeeper root for druid') {|z| @zk_path = z}

    @config.options.on('-h', '--host=HOST',
      'Host to check') { |h| @host = h }

    @config.parse!

    raise "must provide --zookeeper" unless @zk_path
    @host ||= %x{hostname -f}.strip
  end

  def warning(m)
    m[:warning].length > 0
  end

  def critical(m)
    m[:total] == 0 || m[:critical].length > 0
  end

  def to_s(m)
    result = "#{m[:critical].length} old, #{m[:warning].length} stale segments, #{m[:total]} total\n#{m.to_yaml}"
    result
  end

  def measure
    result = {
      total: 0,
      critical: [],
      warning: []
    }
    ZK.open(@zk_path) do |zk|
      zk.children("/druid/segments").each do |host|
        if host.start_with? @host
          zk.children("/druid/segments/#{host}").each do |zk_node|
            raw_content = zk.get("/druid/segments/#{host}/#{zk_node}")[0]
            segments = JSON.parse(
              begin
                Zlib::GzipReader.new(StringIO.new(raw_content)).readlines[0]
              rescue
                raw_content
              end
            )

            segments.each do |segment|
              result[:total] += 1

              interval_start = Time.parse(segment["interval"].split("/")[0])
              label = "#{segment['dataSource']}-#{interval_start.utc}-#{segment['shardSpec']['partitionNum']}"
              if Time.now - interval_start > 24 * 60 * 60
                result[:critical] << label
              elsif Time.now - interval_start > 2 * 60 * 60
                result[:warning] << label
              end
            end
          end
        end
      end
    end
    result
  end
end

CheckDruidSegments.new.run!
