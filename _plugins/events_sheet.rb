require "net/http"
require "csv"
require "date"
require "time"

# Fetches events from a Google Sheet (published as CSV) at build time and
# exposes them as site.data.sheet_events sorted by start date ascending.
#
# Expected sheet columns (header row, case-insensitive — extra columns ignored):
#   date         — YYYY-MM-DD or M/D/YYYY
#   time         — free text, e.g. "10:00 AM" or "10 AM – Noon" (optional)
#   title        — event name
#   location     — venue / address (optional)
#   description  — short blurb (optional)
#   link         — RSVP / details URL (optional)
#
# The sheet must be shared so anyone with the link can view, OR published
# to the web. Otherwise Google returns a 401 sign-in page and no events
# will appear.

module Jekyll
  class EventsSheet < Generator
    safe true
    priority :low

    SHEET_ID = "1rWMT6yLwDc8Fx09fkIYvXfk2h0Apb_T4-E8YmGDPG30".freeze
    GID = "0".freeze
    USER_AGENT = "Mozilla/5.0 (compatible; IndivisibleCarsonCityBot/1.0; +https://indivisiblecarsoncity.org)".freeze

    def generate(site)
      site.data["sheet_events"] = []

      csv_text = fetch_csv
      return if csv_text.nil? || csv_text.empty?

      rows = CSV.parse(csv_text, headers: true)
      events = rows.map { |row| build_event(row) }.compact

      today = Date.today
      upcoming = events.select { |e| e[:date].nil? || e[:date] >= today }
      upcoming.sort_by! { |e| [e[:date] || Date.new(9999, 1, 1), e[:title].to_s] }

      site.data["sheet_events"] = upcoming.map do |e|
        {
          "title"       => e[:title],
          "date"        => e[:date] ? e[:date].strftime("%a, %B %-d, %Y") : nil,
          "iso_date"    => e[:date] ? e[:date].strftime("%Y-%m-%d") : nil,
          "time"        => e[:time],
          "location"    => e[:location],
          "description" => e[:description],
          "link"        => e[:link],
        }
      end
    rescue => e
      Jekyll.logger.warn "EventsSheet:", "Could not load events sheet: #{e.message}"
      site.data["sheet_events"] = []
    end

    private

    def fetch_csv
      url = "https://docs.google.com/spreadsheets/d/#{SHEET_ID}/export?format=csv&gid=#{GID}"
      response = http_get(url, max_redirects: 5)

      unless response.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn "EventsSheet:", "Sheet fetch returned HTTP #{response.code}. Is the sheet shared publicly?"
        return nil
      end

      body = response.body
      # If Google returns the HTML sign-in page, treat as failure.
      if body.lstrip.start_with?("<")
        Jekyll.logger.warn "EventsSheet:", "Sheet returned HTML (likely private). Share the sheet as 'anyone with the link can view'."
        return nil
      end

      body.force_encoding("UTF-8")
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

    def build_event(row)
      h = row.to_h.transform_keys { |k| k.to_s.strip.downcase }
      title = h["title"]&.strip
      return nil if title.nil? || title.empty?

      {
        title:       title,
        date:        parse_date(h["date"]),
        time:        nilify(h["time"]),
        location:    nilify(h["location"]),
        description: nilify(h["description"]),
        link:        nilify(h["link"] || h["rsvp"] || h["url"]),
      }
    end

    def parse_date(value)
      return nil if value.nil? || value.strip.empty?
      Date.parse(value.strip)
    rescue ArgumentError
      nil
    end

    def nilify(value)
      return nil if value.nil?
      stripped = value.to_s.strip
      stripped.empty? ? nil : stripped
    end
  end
end
