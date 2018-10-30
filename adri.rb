#!/usr/bin/env ruby

require 'fileutils'
require 'dotenv/load'
require 'mini_exiftool'
require 'geocoder'
require 'slop'

class Adri
  DEFAULT_PATH_FORMAT = '%Y/%m/%d/%{place}'.freeze
  DEFAULT_PREFIX = '.'.freeze
  VERSION = '0.0.1'.freeze

  class Photo
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
      exif[:GPSLatitude].to_f
    end

    def longitude
      exif[:GPSLongitude].to_f
    end

    def place
      return @place if defined?(@place)

      if skip_geocoding?
        @place = nil
        return
      end

      sleep 1 # TODO: Implement exponential backoff
      geocode_results = Geocoder.search([latitude, longitude])
      places = geocode_results.map(&:city).compact.uniq.first(2)

      @place = places.join(' - ') if places.any?
    end

    def destination_path
      @destination_path ||= File.join(
        prefix,
        sprintf(taken_at.strftime(path_format), place: place),
        File.basename(source_path)
      )
    end

    def move
      if !File.exist?(source_path)
        puts "Skipping missing file #{source_path}" if verbose
        return
      end

      if taken_at.nil?
        puts "Skipping file with no datetime info #{source_path}" if verbose
        return
      end

      if File.exist?(destination_path)
        puts "Skipping existing file #{destination_path}" if verbose
        return
      end

      dest_dir = File.dirname(destination_path)

      if !Dir.exist?(dest_dir)
        puts "Making directory #{dest_dir}" if verbose
        FileUtils.mkdir_p(dest_dir) if run
      end

      puts "Moving file #{source_path} under #{dest_dir}" if verbose
      FileUtils.mv(source_path, destination_path) if run
    end

    private def normalize_path(path)
      File.absolute_path(path)
    end

    private def exif
      @exif ||= MiniExiftool.new(source_path, coord_format: '%.6f')
    end

    private def skip_geocoding?
      path_format['%{place}'].nil?
    end
  end

  def self.print_dry_run_warning(options, prefix: nil, suffix: nil)
    return if options.values_at(:quiet, :run).any?

    print prefix if prefix
    puts '##### DRY RUN #####'
    print suffix if suffix
  end

  def self.parse_args
    opts = Slop.parse do |o|
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

      o.bool(
        '--run',
        'Perform changes instead of performing a dry run'
      )

      o.bool(
        '-q',
        '--quiet',
        'Do not print operations'
      )

      o.on('--version', 'Print the version') do
        puts [$PROGRAM_NAME, VERSION].join(' ')
        exit
      end

      o.on('-h', '--help', 'Print help text') do
        puts o
        exit
      end
    end

    [opts.arguments, opts.to_h]
  end
end

Geocoder.configure(
  lookup: :google,
  api_key: ENV.fetch('GOOGLE_API_KEY')
)

paths, options = Adri.parse_args

Adri.print_dry_run_warning(options, suffix: "\n")

paths.each do |path|
  Adri::Photo.new(path, options).move
end

Adri.print_dry_run_warning(options, prefix: "\n")
