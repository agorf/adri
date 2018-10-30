#!/usr/bin/env ruby

require 'fileutils'
require 'dotenv/load'
require 'mini_exiftool'
require 'geocoder'
require 'slop'

module Adri
  DEFAULT_PATH_FORMAT = '%Y/%m/%d/%{place}'.freeze
  DEFAULT_PREFIX = '.'.freeze
  PLACE_CACHE_SCALE = 2
  VERSION = '0.0.1'.freeze

  class Photo
    class << self
      attr_accessor :place_cache
    end

    self.place_cache = Hash.new(false)

    attr_reader(
      :source_path,
      :prefix,
      :path_format,
      :verbose,
      :run
    )

    def initialize(path, options)
      @source_path = normalize_path(path)
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

    def place
      return @place if defined?(@place)

      if !place_in_path_format? # Skip geocoding if unnecessary
        @place = nil
        return
      end

      @place = read_place_from_cache

      return @place if @place != false

      sleep 1 # TODO: Implement exponential backoff
      geocode_results = Geocoder.search(latlng)
      places = geocode_results.map(&:city).compact.uniq.first(2)
      @place = places.join(' - ') if places.any?

      write_place_to_cache

      @place
    end

    def destination_path
      @destination_path ||= File.join(
        prefix,
        sprintf(taken_at.strftime(path_format), place: place),
        File.basename(source_path)
      )
    end

    def move
      return if skip_move?

      puts "#{source_path} -> #{destination_path}" if verbose

      if run
        dest_dir = File.dirname(destination_path)
        FileUtils.mkdir_p(dest_dir)
        FileUtils.mv(source_path, destination_path)
      end
    end

    private def normalize_path(path)
      File.absolute_path(path)
    end

    private def exif
      @exif ||= MiniExiftool.new(source_path, coord_format: '%.6f')
    end

    private def place_in_path_format?
      path_format['%{place}']
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

      if place_in_path_format?
        if latlng.empty?
          puts "Skipping file with no location info #{source_path}" if verbose
          return true
        end

        if place.nil? # Geocoding failed
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

    private def place_cache_key
      @place_cache_key ||= [
        latitude.truncate(PLACE_CACHE_SCALE).to_s,
        longitude.truncate(PLACE_CACHE_SCALE).to_s
      ]
    end

    private def write_place_to_cache
      self.class.place_cache[place_cache_key] = place
    end

    private def read_place_from_cache
      self.class.place_cache[place_cache_key]
    end
  end

  def self.print_dry_run_banner(options, prefix: nil, suffix: nil)
    return if options.values_at(:quiet, :run).any?

    print prefix if prefix
    print '*' * 35
    print ' DRY RUN '
    puts '*' * 36
    print suffix if suffix
  end

  def self.parse_args
    Slop.parse do |o|
      o.banner = "usage: #{$PROGRAM_NAME} [options] <JPEG photo>..."

      o.string(
        '-p',
        '--prefix',
        "Place everything under this path (default: #{DEFAULT_PREFIX})",
        default: DEFAULT_PREFIX
      )

      o.string(
        '-f',
        '--path-format',
        'Format path with strftime and %{place} (default: ' \
          "#{DEFAULT_PATH_FORMAT})",
        default: DEFAULT_PATH_FORMAT
      )

      o.string(
        '--api-key',
        'Google Maps API key (default: $GOOGLE_API_KEY)',
        default: ENV['GOOGLE_API_KEY']
      )

      o.bool(
        '--run',
        'Perform changes instead of a dry run'
      )

      o.bool(
        '-q',
        '--quiet',
        'Do not print operations'
      )

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

Geocoder.configure(
  lookup: :google,
  api_key: options[:api_key]
)

Adri.print_dry_run_banner(options, suffix: "\n") if paths.any?

paths.each do |path|
  Adri::Photo.new(path, options).move
end

Adri.print_dry_run_banner(options, prefix: "\n") if paths.any?
