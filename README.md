# adri [![Gem Version](https://badge.fury.io/rb/adri.svg)](http://badge.fury.io/rb/adri)

adri organizes JPEG/TIFF photographs according to their EXIF date and location
data into a custom directory structure.

In other words, it turns this:

```sh
$ tree photos/
photos/
├── IMG100001.jpg
├── IMG100002.jpg
└── IMG100003.jpg
```

To this:

```sh
$ tree photos/2018/
photos/2018/
└── 10/
    └── 14/
        └── London
            ├── IMG100001.jpg
            ├── IMG100002.jpg
            └── IMG100003.jpg
```

## Installation

Install the necessary packages. For Debian/Ubuntu, issue:

```sh
sudo apt install ruby-full git build-essential libexif-dev
```

Install adri:

```sh
sudo gem install adri
```

## Configuration

adri converts the GPS coordinates (latitude and longitude) recorded in a
photograph's EXIF headers to a location name using the [Google Maps API][].

To use it, you need a free [API key][] with the Geocoding API enabled.

You can then set the API key in a `GOOGLE_API_KEY` environment variable in your
shell's configuration file. For Bash, issue:

```sh
$ cat >>.~/.bashrc
export GOOGLE_API_KEY=yourapikeyhere
^D
```

Note: `^D` stands for `Ctrl-D`

You can also pass the API key as a command line option with `--api-key`. This
overrides the environment variable.

## Use

To get the help text, issue:

```sh
$ adri -h
usage: adri [options] <path>...
    -p, --prefix       Place everything under this path (default: photo parent directory)
    -f, --path-format  Format path with strftime and %{location} (default: %Y/%m/%d/%{location})
    --api-key          Google Maps API key (default: $GOOGLE_API_KEY)
    --run              Perform changes instead of a dry run
    -q, --quiet        Do not print operations
    --version          Print program version
    -h, --help         Print help text
```

**By default, adri runs in dry run mode.** This means it simply prints out what
it would do, without actually doing it:

```sh
$ pwd
/home/agorf/work/adri/
$ ls -1 photos/*.jpg
IMG100001.jpg
IMG100002.jpg
IMG100003.jpg
$ adri photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100003.jpg (DRY RUN)
$ ls -1 photos/
IMG100001.jpg
IMG100002.jpg
IMG100003.jpg
```

To apply the changes, use the `--run` option:

```sh
$ adri --run photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100001.jpg
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100002.jpg
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100003.jpg
$ tree photos/
photos/
└── 2018/
    └── 10/
        └── 14/
            └── London/
                ├── IMG100001.jpg
                ├── IMG100002.jpg
                └── IMG100003.jpg
```

To place everything under a path other than the parent directory of each
photograph, use the `--prefix` option:

```sh
$ adri --prefix . photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/2018/10/14/London/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/2018/10/14/London/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/2018/10/14/London/IMG100003.jpg (DRY RUN)
```

The default path format is year/month/day/location. It is possible to specify a
custom one with the `--path-format` option:

```sh
$ adri --path-format '%{location}/%b %Y/%d' photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/London/Oct 2018/14/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/London/Oct 2018/14/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/London/Oct 2018/14/IMG100003.jpg (DRY RUN)
```

The date is formatted according to [strftime(3)][strftime].

It's also possible to process many photos at once by passing space-separated
file names and directories (in which case adri will [recurse][]):

```sh
$ adri photos/IMG100001.jpg photos/IMG100002.jpg photos/IMG100003.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100003.jpg (DRY RUN)
$ adri photos/
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100003.jpg (DRY RUN)
```

## License

[MIT][]

## Author

[Angelos Orfanakos](https://agorf.gr/contact/)

[Bundler]: https://bundler.io/
[Google Maps API]: https://developers.google.com/maps/documentation/javascript/examples/geocoding-reverse
[API key]: https://cloud.google.com/maps-platform/#get-started
[MIT]: https://github.com/agorf/adri/blob/master/LICENSE.txt
[recurse]: https://softwareengineering.stackexchange.com/a/184600/316578
[strftime]: http://man7.org/linux/man-pages/man3/strftime.3.html
