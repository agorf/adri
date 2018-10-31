# adri

adri scans the EXIF headers of photographs for date and location (GPS) data and
organizes (moves) them into a custom directory structure by date and location
name using [reverse geocoding][].

## Installation

Clone the repository:

```sh
git clone https://github.com/agorf/adri.git
```

Enter the directory:

```sh
cd adri
```

Install [Ruby][].

Install [Bundler][]:

```sh
gem install bundler
```

Install Gem dependencies with [Bundler][]:

```sh
bundle install
```

## Configuration

To use adri, you need a free [Google Maps API key][]. Make sure the Geocoding
API is enabled!

Once you have that, you need to set it in a `GOOGLE_API_KEY` environment
variable:

```sh
GOOGLE_API_KEY=yourapikeyhere bundle exec adri.rb -h
```

Alternatively, you can place it in an `.env` file in the same directory as adri
and it will be picked up automatically:

```sh
$ cat >.env
GOOGLE_API_KEY=yourapikeyhere
^D
$ cat .env
GOOGLE_API_KEY=yourapikeyhere
```

`^D` stands for `Ctrl-D` (EOF).

Finally, you can also pass the API key as a command line option with
`--api-key`. This overrides the environment variable.

## Use

To get the help text, issue:

```sh
$ bundle exec adri.rb -h
usage: adri.rb [options] <photo>...
    -p, --prefix       Place everything under this path (default: .)
    -f, --path-format  Format path with strftime and %{place} (default: %Y/%m/%d/%{place})
    --api-key          Google Maps API key (default: $GOOGLE_API_KEY)
    --run              Perform changes instead of a dry run
    -q, --quiet        Do not print operations
    --version          Print program version
    -h, --help         Print help text
```

Here's an example:

```sh
$ bundle exec adri.rb IMG_20181014_161221.jpg
/home/agorf/work/adri/IMG_20181014_161221.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161221.jpg (DRY RUN)
```

The default path format is year/month/day/location. It is possible to specify a
custom one:

```sh
$ bundle exec adri.rb --path-format '%{place}/%b %Y/%d' IMG_20181014_161221.jpg
/home/agorf/work/adri/IMG_20181014_161221.jpg -> /home/agorf/work/adri/Kaloskopi - Fokida/Oct 2018/14/IMG_20181014_161221.jpg (DRY RUN)
```

The date is formatted according to [strftime(3)][strftime].

It is possible to place everything under a different path than the current
directory with the `--prefix` option:

```sh
$ bundle exec adri.rb --path-format '%{place}/%b %Y/%d' --prefix ~ IMG_20181014_161221.jpg
/home/agorf/work/adri/IMG_20181014_161221.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG_20181014_161221.jpg (DRY RUN)
```

By default, adri runs in dry run mode. This means it simply prints out what it
would do, without actually doing it. To apply the changes, pass the `--run`
option:

```sh
$ bundle exec adri.rb --path-format '%{place}/%b %Y/%d' --prefix ~ --run IMG_20181014_161221.jpg
/home/agorf/work/adri/IMG_20181014_161221.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG_20181014_161221.jpg
$ tree ~/Kaloskopi\ -\ Fokida
Kaloskopi - Fokida
└── Oct 2018/
    └── 14/
        └── IMG_20181014_161221.jpg
```

It's possible to process many photos at once:

```sh
$ bundle exec adri.rb *.jpg
/home/agorf/work/adri/IMG_20181014_161226.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161226.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161228.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161228.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161231.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161231.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161513.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161513.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161514.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161514.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161521.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161521.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161523.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161523.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161623.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161623.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161628.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161628.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161713.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161713.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_161809.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG_20181014_161809.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164557.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164557.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164558.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164558.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164610.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164610.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164622.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164622.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164646.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164646.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164647.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164647.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164732.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164732.jpg (DRY RUN)
/home/agorf/work/adri/IMG_20181014_164748.jpg -> /home/agorf/work/adri/2018/10/14/Pavliani - Fthiotida/IMG_20181014_164748.jpg (DRY RUN)
```

## License

[MIT][]

## Author

[Angelos Orfanakos](https://agorf.gr/contact/)

[Bundler]: https://bundler.io/
[Google Maps API key]: https://cloud.google.com/maps-platform/#get-started
[MIT]: https://github.com/agorf/adri/blob/master/LICENSE.txt
[Ruby]: https://www.ruby-lang.org/
[reverse geocoding]: https://developers.google.com/maps/documentation/javascript/examples/geocoding-reverse
[strftime]: http://man7.org/linux/man-pages/man3/strftime.3.html
