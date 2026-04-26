require "net/http"
require "rexml/document"

module Jekyll
  class SubstackFeed < Generator
    safe true
    priority :low

    FEED_URL = "https://indivisiblecarsoncity.substack.com/feed"

    def generate(site)
      uri = URI(FEED_URL)
      response = Net::HTTP.get_response(uri)

      # Follow one redirect if needed
      if response.is_a?(Net::HTTPRedirection)
        uri = URI(response["location"])
        response = Net::HTTP.get_response(uri)
      end

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
  end
end
