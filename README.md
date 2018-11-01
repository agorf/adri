# adri

adri organizes (moves) JPEG/TIFF photograph files by date and location into a
custom directory structure. This is done by extracting date and location
information from each file's metadata (EXIF), using [reverse geocoding][] to
convert GPS coordinates to a location.

It automatically turns this:

```sh
$ ls -1 *.jpg
IMG100001.jpg
IMG100002.jpg
IMG100003.jpg
IMG100004.jpg
IMG100005.jpg
```

To this:

```sh
$ tree 2018/
2018/
└── 10/
    └── 14/
        └── Kaloskopi - Fokida
            ├── IMG100001.jpg
            ├── IMG100002.jpg
            ├── IMG100003.jpg
            ├── IMG100004.jpg
            └── IMG100005.jpg
```

## Installation

Clone the repository:

```sh
git clone https://github.com/agorf/adri.git
```

Enter the directory:

```sh
cd adri
```

Install [Ruby][]. In Debian/Ubuntu:

```sh
sudo apt install ruby-full
```

Install [libexif][] development files. In Debian/Ubuntu:

```sh
sudo apt install libexif-dev
```

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
    -f, --path-format  Format path with strftime and %{location} (default: %Y/%m/%d/%{location})
    --api-key          Google Maps API key (default: $GOOGLE_API_KEY)
    --run              Perform changes instead of a dry run
    -q, --quiet        Do not print operations
    --version          Print program version
    -h, --help         Print help text
```

Here's an example:

```sh
$ ls -1 *.jpg
IMG100001.jpg
IMG100002.jpg
IMG100003.jpg
IMG100004.jpg
IMG100005.jpg
$ bundle exec adri.rb IMG100001.jpg
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/work/adri/2018/10/14/Kaloskopi - Fokida/IMG100001.jpg (DRY RUN)
```

The default path format is year/month/day/location. It is possible to specify a
custom one with the `--path-format` option:

```sh
$ bundle exec adri.rb --path-format '%{location}/%b %Y/%d' IMG100001.jpg
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/work/adri/Kaloskopi - Fokida/Oct 2018/14/IMG100001.jpg (DRY RUN)
```

The date (`%b %Y/%d` in the example) is formatted according to
[strftime(3)][strftime].

To place everything under a path other than the current directory, use the
`--prefix` option:

```sh
$ bundle exec adri.rb --path-format '%{location}/%b %Y/%d' --prefix ~ IMG100001.jpg
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100001.jpg (DRY RUN)
```

It's also possible to process many photos at once by passing space-separated
file names and directories (in which case adri will [recurse][]):

```sh
$ bundle exec adri.rb --path-format '%{location}/%b %Y/%d' --prefix ~ IMG100001.jpg IMG100002.jpg
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/IMG100002.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100002.jpg (DRY RUN)
$ bundle exec adri.rb --path-format '%{location}/%b %Y/%d' --prefix ~ *.jpg
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/IMG100002.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/IMG100003.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100003.jpg (DRY RUN)
/home/agorf/work/adri/IMG100004.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100004.jpg (DRY RUN)
/home/agorf/work/adri/IMG100005.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100005.jpg (DRY RUN)
$ bundle exec adri.rb --path-format '%{location}/%b %Y/%d' --prefix ~ .
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/IMG100002.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/IMG100003.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100003.jpg (DRY RUN)
/home/agorf/work/adri/IMG100004.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100004.jpg (DRY RUN)
/home/agorf/work/adri/IMG100005.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100005.jpg (DRY RUN)
```

By default, adri runs in dry run mode. This means it simply prints out what it
would do, without actually doing it. To apply the changes, use the `--run`
option:

```sh
$ bundle exec adri.rb --path-format '%{location}/%b %Y/%d' --prefix ~ --run *.jpg
/home/agorf/work/adri/IMG100001.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100001.jpg
/home/agorf/work/adri/IMG100002.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100002.jpg
/home/agorf/work/adri/IMG100003.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100003.jpg
/home/agorf/work/adri/IMG100004.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100004.jpg
/home/agorf/work/adri/IMG100005.jpg -> /home/agorf/Kaloskopi - Fokida/Oct 2018/14/IMG100005.jpg
$ tree ~/Kaloskopi\ -\ Fokida
Kaloskopi - Fokida/
└── Oct 2018/
    └── 14/
        ├── IMG100001.jpg
        ├── IMG100002.jpg
        ├── IMG100003.jpg
        ├── IMG100004.jpg
        └── IMG100005.jpg
```

## License

[MIT][]

## Author

[Angelos Orfanakos](https://agorf.gr/contact/)

[Bundler]: https://bundler.io/
[exiftool]: https://www.sno.phy.queensu.ca/~phil/exiftool/
[Google Maps API key]: https://cloud.google.com/maps-platform/#get-started
[libexif]: https://libexif.github.io/
[MIT]: https://github.com/agorf/adri/blob/master/LICENSE.txt
[Ruby]: https://www.ruby-lang.org/en/documentation/installation/
[recurse]: https://softwareengineering.stackexchange.com/a/184600/316578
[reverse geocoding]: https://developers.google.com/maps/documentation/javascript/examples/geocoding-reverse
[strftime]: http://man7.org/linux/man-pages/man3/strftime.3.html
