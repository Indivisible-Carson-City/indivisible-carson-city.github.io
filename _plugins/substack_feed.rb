require "net/http"
require "rexml/document"
require "yaml"

module Jekyll
  class SubstackFeed < Generator
    safe true
    priority :low

    FEED_URL = "https://indivisiblecarsoncity.substack.com/feed"
    USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
    CACHE_FILE = "_data/substack_cache.yml"

    def generate(site)
      items = fetch_and_parse
      if items && !items.empty?
        site.data["substack_posts"] = items
        save_cache(site, items)
      else
        cached = load_cache(site)
        if cached && !cached.empty?
          Jekyll.logger.info "SubstackFeed:", "Using cached posts (#{cached.length} posts)"
          site.data["substack_posts"] = cached
        else
          site.data["substack_posts"] = []
        end
      end
    end

    private

    def fetch_and_parse
      response = http_get(FEED_URL, max_redirects: 5)

      unless response.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn "SubstackFeed:", "Could not fetch feed: HTTP #{response.code}"
        return nil
      end

      doc = REXML::Document.new(response.body)
      items = []

      doc.elements.each("rss/channel/item") do |item|
        break if items.length >= 5

        pub_date = item.elements["pubDate"]&.text
        formatted_date = if pub_date
          Time.parse(pub_date).strftime("%B %-d, %Y")
        end

        items << {
          "title"       => item.elements["title"]&.text || "Untitled",
          "link"        => item.elements["link"]&.text,
          "date"        => formatted_date,
          "description" => item.elements["description"]&.text,
        }
      end

      items
    rescue => e
      Jekyll.logger.warn "SubstackFeed:", "Could not fetch feed: #{e.message}"
      nil
    end

    def save_cache(site, items)
      path = File.join(site.source, CACHE_FILE)
      File.write(path, items.to_yaml)
      Jekyll.logger.info "SubstackFeed:", "Cached #{items.length} posts to #{CACHE_FILE}"
    rescue => e
      Jekyll.logger.warn "SubstackFeed:", "Could not write cache: #{e.message}"
    end

    def load_cache(site)
      path = File.join(site.source, CACHE_FILE)
      return nil unless File.exist?(path)
      YAML.safe_load(File.read(path), permitted_classes: [Date, Time])
    rescue => e
      Jekyll.logger.warn "SubstackFeed:", "Could not read cache: #{e.message}"
      nil
    end

    def http_get(url, max_redirects: 5)
      uri = URI(url)
      max_redirects.times do
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = USER_AGENT
        req["Accept"] = "application/rss+xml, application/xml, text/xml, */*"
        req["Accept-Language"] = "en-US,en;q=0.9"
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
          http.request(req)
        end
        return response unless response.is_a?(Net::HTTPRedirection)
        location = response["location"]
        return response unless location
        uri = URI.join(uri.to_s, location)
      end
      raise "Too many redirects"
    end
  end
end
