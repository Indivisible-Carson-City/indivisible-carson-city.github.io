require "net/http"
require "json"
require "yaml"

module Jekyll
  class SubstackFeed < Generator
    safe true
    priority :low

    FEED_URL = "https://api.rss2json.com/v1/api.json?rss_url=https://indivisiblecarsoncity.substack.com/feed"
    USER_AGENT = "Mozilla/5.0 (compatible; IndivisibleCarsonCityBot/1.0; +https://indivisiblecarsoncity.org)"
    CACHE_FILE = "_data/substack_cache.yml"

    def generate(site)
      items = fetch_posts
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

    def fetch_posts
      uri = URI(FEED_URL)
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = USER_AGENT
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
        http.request(req)
      end

      raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      raise "API error: #{data['message']}" unless data["status"] == "ok"

      data["items"].first(5).map do |item|
        pub_date = item["pubDate"]
        formatted_date = if pub_date && !pub_date.empty?
          Time.parse(pub_date).strftime("%B %-d, %Y")
        end

        {
          "title"       => item["title"] || "Untitled",
          "link"        => item["link"],
          "date"        => formatted_date,
          "description" => item["description"]&.then { |d| d.gsub(/<[^>]+>/, "").strip[0, 200] },
        }
      end
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
  end
end
