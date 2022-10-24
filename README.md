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
$ tree photos/
photos/
└── 2018/
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

### API key

The GPS coordinates (latitude, longitude) of each photograph's EXIF headers are
converted to a corresponding location name using the [Google Maps API][]. For
this, you need a free [API key][] with the Geocoding API enabled.

You can set the `ADRI_GOOGLE_API_KEY` environment variable in your shell's
configuration file. For Bash, issue:

```sh
$ cat >>.~/.bashrc
export ADRI_GOOGLE_API_KEY=yourapikeyhere
^D
```

Note: `^D` stands for `Ctrl-D`

You can also pass the API key as a command line option with `--api-key`. This
overrides the environment variable.

### Location language

It's possible to configure the language (default is `en` for English) used in
location names by setting the `ADRI_LOCALE` environment variable in your shell's
configuration file.

To set the language to Greek in Bash, issue:

```sh
$ cat >>.~/.bashrc
export ADRI_LOCALE=el
^D
```

Note: `^D` stands for `Ctrl-D`

You can also pass the language as a command line option with `--locale`. This
overrides the environment variable.

## Use

To get the help text, issue:

```sh
$ adri -h
usage: adri [options] <path>...
    -p, --prefix       Place everything under this path (default: photo parent directory)
    -f, --path-format  Format path with strftime and %{location} (default: %Y/%m/%d/%{location})
    --api-key          Google Maps API key (default: $ADRI_GOOGLE_API_KEY)
    --locale           Locale to use for %{location} in path format (default: $ADRI_LOCALE or en)
    --run              Perform changes instead of a dry run
    -q, --quiet        Do not print operations
    --version          Print program version
    -h, --help         Print help text
```

### Dry run mode (default)

By default, adri runs in dry run mode, printing `(DRY RUN)` at the end of each
line. This means it simply prints out what it would do, without actually doing
it:

```sh
$ pwd
/home/agorf/work/adri/
$ tree photos/
photos/
├── IMG100001.jpg
├── IMG100002.jpg
└── IMG100003.jpg
$ adri photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/2018/10/14/London/IMG100003.jpg (DRY RUN)
$ tree photos/
photos/
├── IMG100001.jpg
├── IMG100002.jpg
└── IMG100003.jpg
```

### Run mode

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

### Path prefix

To place everything under a path other than the parent directory of each
photograph, use the `--prefix` option:

```sh
$ adri --prefix . photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/2018/10/14/London/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/2018/10/14/London/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/2018/10/14/London/IMG100003.jpg (DRY RUN)
```

### Path format

The default path format is `%Y/%m/%d/%{location}` which stands for
_year/month/day/location_. Everything other than `%{location}` is formatted
according to [strftime(3)][strftime].

It is possible to specify a custom path with the `--path-format` option:

```sh
$ adri --path-format '%{location}/%b %Y/%d' photos/*.jpg
/home/agorf/work/adri/photos/IMG100001.jpg -> /home/agorf/work/adri/photos/London/Oct 2018/14/IMG100001.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100002.jpg -> /home/agorf/work/adri/photos/London/Oct 2018/14/IMG100002.jpg (DRY RUN)
/home/agorf/work/adri/photos/IMG100003.jpg -> /home/agorf/work/adri/photos/London/Oct 2018/14/IMG100003.jpg (DRY RUN)
```

### Processing many photos

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
