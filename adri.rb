#!/usr/bin/env ruby

require 'fileutils'
require 'time'

require 'dotenv/load'
require 'exif'
require 'geocoder'
require 'slop'

module Adri
  DEFAULT_PATH_FORMAT = '%Y/%m/%d/%{location}'.freeze
  EXTENSIONS = %w[jpg jpeg JPG JPEG tif tiff TIF TIFF].freeze
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
      :dry_run
    )

    def initialize(path, options)
      @source_path = File.absolute_path(path)
      @path_format = options[:path_format].gsub('/', File::SEPARATOR)
      @verbose = !options[:quiet]
      @dry_run = !options[:run]

      @prefix =
        if options[:prefix].to_s.strip.empty?
          File.dirname(@source_path)
        else
          File.absolute_path(options[:prefix])
        end
    end

    def date_time
      return @date_time if @date_time

      if exif&.date_time && exif.date_time != '0000:00:00 00:00:00'
        @date_time = Time.strptime(exif.date_time, '%Y:%m:%d %H:%M:%S')
      end
    end

    def latitude
      return @latitude if @latitude

      if exif&.gps_latitude
        @latitude = geo_float(exif.gps_latitude)
      end
    end

    def longitude
      return @longitude if @longitude

      if exif&.gps_longitude
        @longitude = geo_float(exif.gps_longitude)
      end
    end

    def location
      return @location if defined?(@location)

      @location = read_location_from_cache

      return @location if @location != false

      @location = location_from_latlng

      write_location_to_cache

      @location
    end

    def destination_path
      return @destination_path if @destination_path

      path = date_time.strftime(path_format)

      if location_in_path_format?
        path = sprintf(path, location: location)
      end

      @destination_path ||= File.join(
        prefix,
        path,
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
          dry_run ? ' (DRY RUN)' : ''
        )
      end

      return if dry_run

      FileUtils.mkdir_p(File.dirname(destination_path))
      FileUtils.mv(source_path, destination_path)
    end

    private def exif
      begin
        @exif ||= Exif::Data.new(File.open(source_path))
      rescue Exif::NotReadable
      end
    end

    private def location_in_path_format?
      path_format['%{location}']
    end

    private def latlng
      @latlng ||= [latitude, longitude].compact
    end

    private def skip_move?
      if !File.exist?(source_path)
        puts "Missing file #{source_path}" if verbose
        return true
      end

      if date_time.nil?
        puts "No datetime data #{source_path}" if verbose
        return true
      end

      if location_in_path_format?
        if latlng.empty?
          puts "No location data #{source_path}" if verbose
          return true
        end

        if location.nil? # Geocoding failed
          puts "Unknown location #{source_path}" if verbose
          return true
        end
      end

      if File.exist?(destination_path)
        puts "Existing file #{destination_path}" if verbose
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

      geocode_results.map(&:city).compact.uniq.first
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

    private def geo_float(value)
      degrees, minutes, seconds = value
      degrees + minutes / 60.0 + seconds / 3600.0
    end
  end

  def self.parse_args
    Slop.parse do |o|
      o.banner = "usage: #{$PROGRAM_NAME} [options] <path>..."

      o.string(
        '-p',
        '--prefix',
        'Place everything under this path (default: photo parent directory)'
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

  def self.expand_paths(paths, verbose)
    glob_pattern = File.join('**', "*.{#{EXTENSIONS.join(',')}}")

    Enumerator.new do |y|
      paths.each do |path|
        file_paths =
          if FileTest.directory?(path)
            Dir.glob(File.join(path, glob_pattern)).sort
          elsif !File.exist?(path)
            puts "Missing #{path}" if verbose
          elsif !FileTest.file?(path) || FileTest.symlink?(path)
            puts "Not a file #{path}" if verbose
          elsif !EXTENSIONS.include?(File.extname(path).delete('.'))
            if verbose
              puts "File extension not one of: #{EXTENSIONS.join(', ')}"
            end
          else
            [path]
          end || []

        file_paths.each do |file_path|
          y << file_path
        end
      end
    end
  end
end

opts = Adri.parse_args
args = opts.arguments

if args.empty?
  puts opts
  exit
end

options = opts.to_h

if options[:path_format]['%{location}'] && options[:api_key].to_s.strip.empty?
  puts 'Please specify a Google Maps API key or remove %{location} from path ' \
    'format'
  exit 1
end

Geocoder.configure(
  always_raise: :all,
  lookup: :google,
  api_key: options[:api_key]
)

Adri.expand_paths(args, !options[:quiet]).each do |path|
  Adri::Photo.new(path, options).move
end
