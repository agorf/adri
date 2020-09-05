# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][] and this project adheres to
[Semantic Versioning][].

## [Unreleased][]

## [0.1.0][] - 2020-09-06

### Added

- Make language of geocoding results configurable through the
  `GEOCODER_LANGUAGE` environment variable (default is `en` for English)

### Changed

- Update README file
- Update Gem dependencies
- Improve specificity of extracted location
- Increase geocoding timeout from 3 to 10 seconds
- Handle geocoding timeout errors

## [0.0.1][] - 2018-12-06

Initial release.

[Keep a Changelog]: http://keepachangelog.com/en/1.0.0/
[Semantic Versioning]: http://semver.org/spec/v2.0.0.html
[Unreleased]: https://github.com/agorf/adri/compare/0.1.0...HEAD
[0.1.0]: https://github.com/agorf/adri/compare/0.0.1...0.1.0
[0.0.1]: https://github.com/agorf/adri/releases/tag/0.0.1
