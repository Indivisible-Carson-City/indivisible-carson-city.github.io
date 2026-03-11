(function () {
  var API_URL =
    "https://api.mobilize.us/v1/organizations/47081/events?timeslot_start=gte_now&per_page=";
  var MOBILIZE_PAGE = "https://www.mobilize.us/indivisiblecarsoncity/";

  function formatDate(dateString) {
    var d = new Date(dateString);
    return d.toLocaleDateString("en-US", {
      weekday: "short",
      month: "long",
      day: "numeric",
      year: "numeric",
    });
  }

  function formatTime(dateString) {
    var d = new Date(dateString);
    return d.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
    });
  }

  function buildCard(event) {
    var title = event.title || "Untitled Event";
    var url = event.browser_url || MOBILIZE_PAGE;
    var description = event.description || "";
    // Trim description to ~150 chars
    if (description.length > 150) {
      description = description.substring(0, 150).replace(/\s+\S*$/, "") + "...";
    }

    // Get first timeslot for date/time
    var dateStr = "";
    if (event.timeslots && event.timeslots.length > 0) {
      var slot = event.timeslots[0];
      dateStr =
        formatDate(slot.start_date * 1000) +
        " at " +
        formatTime(slot.start_date * 1000);
    }

    // Location
    var location = "";
    if (event.location) {
      var parts = [];
      if (event.location.venue) parts.push(event.location.venue);
      if (event.location.locality) parts.push(event.location.locality);
      if (event.location.region) parts.push(event.location.region);
      location = parts.join(", ");
    }

    var card = document.createElement("div");
    card.className =
      "bg-white rounded-xl shadow-sm hover:shadow-md hover:-translate-y-0.5 transition-all p-6";

    card.innerHTML =
      '<h3 class="font-heading font-bold text-lg mb-2">' +
      escapeHtml(title) +
      "</h3>" +
      '<p class="text-sm text-gray-500 mb-3">' +
      (dateStr ? escapeHtml(dateStr) : "") +
      (location ? "<br>" + escapeHtml(location) : "") +
      "</p>" +
      '<p class="text-gray-600 mb-4">' +
      escapeHtml(description) +
      "</p>" +
      '<a href="' +
      escapeHtml(url) +
      '" class="inline-block bg-accent hover:bg-accent-dark text-white text-sm font-semibold px-4 py-2 rounded-full transition-colors" target="_blank" rel="noopener">RSVP</a>';

    return card;
  }

  function escapeHtml(str) {
    var div = document.createElement("div");
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
  }

  function renderFallback(container) {
    container.innerHTML =
      '<div class="text-center">' +
      '<p class="text-gray-500 mb-4">Unable to load events right now.</p>' +
      '<a href="' +
      MOBILIZE_PAGE +
      '" class="inline-block bg-accent hover:bg-accent-dark text-white font-semibold px-6 py-3 rounded-full transition-colors" target="_blank" rel="noopener">View Events on Mobilize</a>' +
      "</div>";
  }

  function loadEvents(containerId, limit) {
    var container = document.getElementById(containerId);
    if (!container) return;

    // Show loading spinner
    container.innerHTML =
      '<div class="text-center py-8">' +
      '<div class="inline-block w-8 h-8 border-4 border-gray-200 border-t-brand rounded-full animate-spin"></div>' +
      "</div>";

    fetch(API_URL + limit)
      .then(function (response) {
        if (!response.ok) throw new Error("API error");
        return response.json();
      })
      .then(function (data) {
        var events = data.data || [];
        if (events.length === 0) {
          container.innerHTML =
            '<p class="text-center text-gray-400">No upcoming events. Check back soon!</p>';
          return;
        }

        var grid = document.createElement("div");
        grid.className = "grid md:grid-cols-3 gap-6";

        events.forEach(function (event) {
          grid.appendChild(buildCard(event));
        });

        container.innerHTML = "";
        container.appendChild(grid);
      })
      .catch(function () {
        renderFallback(container);
      });
  }

  // Expose globally so pages can call it
  window.loadMobilizeEvents = loadEvents;
})();
