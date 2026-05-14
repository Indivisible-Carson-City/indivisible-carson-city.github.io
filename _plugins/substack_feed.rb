require "net/http"
require "rexml/document"

module Jekyll
  class SubstackFeed < Generator
    safe true
    priority :low

    FEED_URL = "https://indivisiblecarsoncity.substack.com/feed"
    USER_AGENT = "Mozilla/5.0 (compatible; IndivisibleCarsonCityBot/1.0; +https://indivisiblecarsoncity.org)"

    def generate(site)
      response = http_get(FEED_URL, max_redirects: 5)

      raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

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

      site.data["substack_posts"] = items
    rescue => e
      Jekyll.logger.warn "SubstackFeed:", "Could not fetch feed: #{e.message}"
      site.data["substack_posts"] = []
    end

    private

    def http_get(url, max_redirects: 5)
      uri = URI(url)
      max_redirects.times do
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = USER_AGENT
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
