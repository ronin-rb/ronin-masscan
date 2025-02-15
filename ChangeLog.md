### 0.1.1 / 2025-02-14

* Added the `csv` gem as a dependency for Bundler and Ruby 3.4.0.
* Use `require_relative` to improve load times.

### 0.1.0 / 2024-07-22

* Initial release:
  * Supports automating `masscan` using [ruby-masscan].
  * Supports parsing and filtering masscan scan files.
  * Supports converting masscan scan files into JSON or CSV.
  * Supports importing masscan scan files into the [ronin-db] database.

[ruby-masscan]: https://github.com/postmodern/ruby-masscan#readme
[ronin-db]: https://github.com/ronin-rb/ronin-db#readme
