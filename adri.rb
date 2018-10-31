#!/usr/bin/env ruby

require 'fileutils'
require 'dotenv/load'
require 'mini_exiftool'
require 'geocoder'
require 'slop'

module Adri
  DEFAULT_PATH_FORMAT = '%Y/%m/%d/%{location}'.freeze
  DEFAULT_PREFIX = '.'.freeze
  GEOCODE_MAX_DELAY = 60 # Seconds
  LOCATION_CACHE_SCALE = 2
  VERSION = '0.0.1'.freeze

  class Photo
    class << self
      attr_accessor :location_cache
    end

    self.location_cache = Hash.new(false)

    attr_reader(
      :source_path,
      :prefix,
      :path_format,
      :verbose,
      :run
    )

    def initialize(path, options)
      @source_path = File.absolute_path(path)
      @prefix = File.absolute_path(options[:prefix])
      @path_format = options[:path_format].gsub('/', File::SEPARATOR)
      @verbose = !options[:quiet]
      @run = options[:run]
    end

    def taken_at
      @taken_at ||= exif[:DateTimeOriginal]
    end

    def latitude
      exif[:GPSLatitude]&.to_f
    end

    def longitude
      exif[:GPSLongitude]&.to_f
    end

    def location
      return @location if defined?(@location)

      if !location_in_path_format? # Skip geocoding if unnecessary
        @location = nil
        return
      end

      @location = read_location_from_cache

      return @location if @location != false

      @location = location_from_latlng

      write_location_to_cache

      @location
    end

    def destination_path
      @destination_path ||= File.join(
        prefix,
        sprintf(taken_at.strftime(path_format), location: location),
        File.basename(source_path)
      )
    end

    def move
      return if skip_move?

      if verbose
        puts sprintf(
          '%s -> %s%s',
          source_path,
          destination_path,
          run ? '' : ' (DRY RUN)'
        )
      end

      return if !run

      FileUtils.mkdir_p(File.dirname(destination_path))
      FileUtils.mv(source_path, destination_path)
    end

    private def exif
      @exif ||= MiniExiftool.new(source_path, coord_format: '%.6f')
    end

    private def location_in_path_format?
      path_format['%{location}']
    end

    private def latlng
      [latitude, longitude].compact
    end

    private def skip_move?
      if !File.exist?(source_path)
        puts "Skipping missing file #{source_path}" if verbose
        return true
      end

      if taken_at.nil?
        puts "Skipping file with no datetime info #{source_path}" if verbose
        return true
      end

      if location_in_path_format?
        if latlng.empty?
          puts "Skipping file with no location info #{source_path}" if verbose
          return true
        end

        if location.nil? # Geocoding failed
          puts "Skipping file with unknown location #{source_path}" if verbose
          return true
        end
      end

      if File.exist?(destination_path)
        puts "Skipping existing file #{destination_path}" if verbose
        return true
      end

      false
    end

    private def location_from_latlng
      current_delay = 0.1 # 100 ms

      begin
        geocode_results = Geocoder.search(latlng)
      rescue Geocoder::OverQueryLimitError
        puts 'Got OverQueryLimitError' if verbose

        if current_delay > GEOCODE_MAX_DELAY
          puts "Exceeded max delay of #{GEOCODE_MAX_DELAY} seconds" if verbose
          return
        end

        puts "Waiting #{current_delay} seconds before retrying..." if verbose
        sleep(current_delay)
        current_delay *= 2 # Exponential backoff

        retry
      end

      cities = geocode_results.map(&:city).compact.uniq.first(2)
      cities.join(' - ') if cities.any?
    end

    private def location_cache_key
      @location_cache_key ||= [
        latitude.truncate(LOCATION_CACHE_SCALE).to_s,
        longitude.truncate(LOCATION_CACHE_SCALE).to_s
      ]
    end

    private def write_location_to_cache
      self.class.location_cache[location_cache_key] = location
    end

    private def read_location_from_cache
      self.class.location_cache[location_cache_key]
    end
  end

  def self.parse_args
    Slop.parse do |o|
      o.banner = "usage: #{$PROGRAM_NAME} [options] <photo>..."

      o.string(
        '-p',
        '--prefix',
        "Place everything under this path (default: #{DEFAULT_PREFIX})",
        default: DEFAULT_PREFIX
      )

      o.string(
        '-f',
        '--path-format',
        'Format path with strftime and %{location} (default: ' \
          "#{DEFAULT_PATH_FORMAT})",
        default: DEFAULT_PATH_FORMAT
      )

      o.string(
        '--api-key',
        'Google Maps API key (default: $GOOGLE_API_KEY)',
        default: ENV['GOOGLE_API_KEY']
      )

      o.bool('--run', 'Perform changes instead of a dry run')

      o.bool('-q', '--quiet', 'Do not print operations')

      o.on('--version', 'Print program version') do
        puts [$PROGRAM_NAME, VERSION].join(' ')
        exit
      end

      o.on('-h', '--help', 'Print help text') do
        puts o
        exit
      end
    end
  end
end

opts = Adri.parse_args
paths = opts.arguments

if paths.empty?
  puts opts
  exit
end

options = opts.to_h

if options[:api_key].to_s.strip.empty?
  puts 'Please specify a Google Maps API key'
  exit 1
end

Geocoder.configure(
  always_raise: :all,
  lookup: :google,
  api_key: options[:api_key]
)

paths.each do |path|
  Adri::Photo.new(path, options).move
end
