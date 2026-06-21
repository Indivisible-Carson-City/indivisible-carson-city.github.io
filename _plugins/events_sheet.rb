require "net/http"
require "csv"
require "date"
require "time"
require "yaml"

# Fetches events from the Indivisible Carson City Google Sheet (exported as
# CSV) at build time and exposes them as site.data.sheet_events, sorted by
# start date ascending, filtered to upcoming events only.
#
# Resilience:
#   * The parser is deliberately forgiving — headers are matched fuzzily
#     (case/spacing-insensitive, "contains" matching), whitespace-only cells
#     are treated as blank, and several date/time formats are accepted.
#   * On a successful fetch the results are cached to _data/sheet_events_cache.yml.
#     If a later build can't reach the sheet, the cached events are used so the
#     page never goes empty.
#   * Set the EVENTS_SHEET_CSV env var to a local CSV path to bypass the network
#     (used for local development / testing).
#
# Sheet columns (header row, matched fuzzily):
#   Start Date, End Date, Event Name, Start Time, End Time, Location,
#   Description, Register Here Hyperlink Text, More Information Hyperlink Text
module Jekyll
  class EventsSheet < Generator
    safe true
    priority :low

    SHEET_ID = "1rWMT6yLwDc8Fx09fkIYvXfk2h0Apb_T4-E8YmGDPG30".freeze
    GID = "0".freeze
    CACHE_FILE = "_data/sheet_events_cache.yml".freeze
    USER_AGENT = "Mozilla/5.0 (compatible; IndivisibleCarsonCityBot/1.0; +https://indivisiblecarsoncity.org)".freeze

    def generate(site)
      csv_text = local_override || fetch_csv
      events = csv_text ? self.class.parse_csv(csv_text) : nil

      if events && !events.empty?
        site.data["sheet_events"] = events
        save_cache(site, events)
        Jekyll.logger.info "EventsSheet:", "Loaded #{events.length} upcoming events from sheet"
      else
        cached = load_cache(site)
        site.data["sheet_events"] = cached || []
        if cached && !cached.empty?
          Jekyll.logger.info "EventsSheet:", "Using #{cached.length} cached events (live fetch unavailable)"
        else
          Jekyll.logger.warn "EventsSheet:", "No events available (fetch failed and no cache)"
        end
      end
    end

    # ---------------------------------------------------------------------
    # Parsing (pure functions — no network, no Jekyll state — so they can be
    # exercised by a plain `jekyll build` with EVENTS_SHEET_CSV set).
    # ---------------------------------------------------------------------

    def self.parse_csv(csv_text)
      csv_text = csv_text.to_s.dup.force_encoding("UTF-8")
      rows = CSV.parse(csv_text, headers: true)
      events = rows.map { |row| build_event(row) }.compact
      today = Date.today.strftime("%Y-%m-%d")
      events.select! { |e| upcoming?(e, today) }
      events.sort_by { |e| [e["iso_date"] || "9999-99-99", e["title"].to_s] }
    end

    def self.build_event(row)
      h = {}
      row.to_h.each { |k, v| h[normalize_key(k)] = v }

      title = clean(pick(h, %w[event name]) || pick(h, %w[title]) || pick(h, %w[name]))
      return nil if title.nil?

      start_date = parse_date(pick(h, %w[start date]) || pick(h, %w[date], exclude: %w[end]))
      end_date   = parse_date(pick(h, %w[end date]))

      {
        "title"        => title,
        "iso_date"     => start_date&.strftime("%Y-%m-%d"),
        "iso_end"      => end_date&.strftime("%Y-%m-%d"),
        "date_display" => format_date(start_date),
        "end_display"  => format_short(end_date),
        "time_display" => format_time_range(pick(h, %w[start time]) || pick(h, %w[time], exclude: %w[end]),
                                            pick(h, %w[end time])),
        "location"     => clean(pick(h, %w[location]) || pick(h, %w[venue])),
        "description"  => clean(pick(h, %w[description])),
        "register_url" => clean_url(pick(h, %w[register])),
        "more_url"     => clean_url(pick(h, %w[more])),
      }
    end

    # Keep events whose last relevant day is today or later. Undated events
    # are always kept (we can't filter what we can't read).
    def self.upcoming?(event, today_iso)
      last = event["iso_end"] || event["iso_date"]
      return true if last.nil?
      last >= today_iso
    end

    # Find the first non-blank value whose normalized header contains all of
    # `includes` and none of `exclude`. Iterates in column order.
    def self.pick(hash, includes, exclude: [])
      hash.each do |key, value|
        next if blank?(value)
        next unless includes.all? { |needle| key.include?(needle) }
        next if exclude.any? { |needle| key.include?(needle) }
        return value
      end
      nil
    end

    def self.normalize_key(key)
      key.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
    end

    def self.blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    def self.clean(value)
      return nil if blank?(value)
      value.to_s.strip
    end

    def self.clean_url(value)
      s = clean(value)
      return nil if s.nil?
      return s if s =~ %r{\Ahttps?://}i
      return "https://#{s}" if s =~ /\Awww\./i
      nil
    end

    # Parse dates US-style (month first). Ruby's Date.parse treats "6/9/2026"
    # as day-first, which is wrong for this sheet, so handle slash dates
    # explicitly. Also accepts ISO (2026-09-12) and month-name forms used in
    # the End Date column ("May 29", "June 5" — year defaults to current).
    def self.parse_date(value)
      s = clean(value)
      return nil if s.nil?

      if (m = s.match(%r{\A(\d{1,2})/(\d{1,2})/(\d{2,4})\z}))
        year = m[3].to_i
        year += 2000 if year < 100
        return safe_date(year, m[1].to_i, m[2].to_i)
      end

      if (m = s.match(/\A(\d{4})-(\d{1,2})-(\d{1,2})\z/))
        return safe_date(m[1].to_i, m[2].to_i, m[3].to_i)
      end

      begin
        Date.parse(s)
      rescue ArgumentError
        nil
      end
    end

    def self.safe_date(year, month, day)
      Date.new(year, month, day)
    rescue ArgumentError
      nil
    end

    # "Sat, September 12" — weekday + month + day, no year (per stakeholder).
    def self.format_date(date)
      return nil if date.nil?
      date.strftime("%a, %B %-d")
    end

    # "September 12" — used for the end of a multi-day range.
    def self.format_short(date)
      return nil if date.nil?
      date.strftime("%B %-d")
    end

    # "3:00 pm – 5:00 pm" (lowercase am/pm). End is optional.
    def self.format_time_range(start_time, end_time)
      s = lower_meridiem(clean(start_time))
      e = lower_meridiem(clean(end_time))
      return nil if s.nil? && e.nil?
      return e if s.nil?
      return s if e.nil?
      "#{s} – #{e}"
    end

    def self.lower_meridiem(value)
      return nil if value.nil?
      value.sub(/\s*([AP])\.?M\.?\b/i) { " #{Regexp.last_match(1).downcase}m" }.strip
    end

    # ---------------------------------------------------------------------
    # Fetch + cache
    # ---------------------------------------------------------------------

    private

    def local_override
      path = ENV["EVENTS_SHEET_CSV"]
      return nil unless path && File.exist?(path)
      Jekyll.logger.info "EventsSheet:", "Using local CSV override: #{path}"
      File.read(path, encoding: "UTF-8")
    end

    def fetch_csv
      url = "https://docs.google.com/spreadsheets/d/#{SHEET_ID}/export?format=csv&gid=#{GID}"
      response = http_get(url)

      unless response.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn "EventsSheet:", "Sheet fetch returned HTTP #{response.code}. Is it shared 'anyone with the link'?"
        return nil
      end

      body = response.body.to_s
      if body.lstrip.start_with?("<")
        Jekyll.logger.warn "EventsSheet:", "Sheet returned HTML (likely private). Share as 'anyone with the link can view'."
        return nil
      end

      body.force_encoding("UTF-8")
    rescue => e
      Jekyll.logger.warn "EventsSheet:", "Could not fetch sheet: #{e.message}"
      nil
    end

    def http_get(url, max_redirects: 5)
      uri = URI(url)
      max_redirects.times do
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = USER_AGENT
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
          http.request(req)
        end
        return response unless response.is_a?(Net::HTTPRedirection)
        location = response["location"]
        return response unless location
        uri = URI.join(uri.to_s, location)
      end
      raise "Too many redirects"
    end

    def save_cache(site, events)
      path = File.join(site.source, CACHE_FILE)
      File.write(path, events.to_yaml)
    rescue => e
      Jekyll.logger.warn "EventsSheet:", "Could not write cache: #{e.message}"
    end

    def load_cache(site)
      path = File.join(site.source, CACHE_FILE)
      return nil unless File.exist?(path)
      YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
    rescue => e
      Jekyll.logger.warn "EventsSheet:", "Could not read cache: #{e.message}"
      nil
    end
  end
end
