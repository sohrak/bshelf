// app/javascript/controllers/isbn_lookup_controller.js
import { Controller } from "@hotwired/stimulus"
import { FetchRequest } from '@rails/request.js' // For making requests

export default class extends Controller {
  // Define targets for elements we need to interact with
  static targets = [
    "isbn",
    "status",
    "title",
    "author",
    "genre",
    "publisher",
    "publicationDate", // Matches form field name
    "pageCount",       // Matches form field name
    "description"      // Optional: if you want to populate description
  ]

  // Define the URL value passed from the form
  static values = {
    url: String
  }

  // Action triggered by the button click
  async lookup(event) {
    event.preventDefault(); // Prevent any default button behavior
    const isbnValue = this.isbnTarget.value.trim().replace(/-/g, ''); // Clean ISBN

    if (!isbnValue) {
      this.setStatus("Please enter an ISBN.", "error");
      this.isbnTarget.focus();
      return;
    }

    // Construct the actual URL by replacing the placeholder
    const lookupUrl = this.urlValue.replace(':isbn', isbnValue);

    this.setStatus("Looking up...", "loading");
    // Disable button temporarily? Optional. Find the button relative to the event target.
    const button = event.currentTarget;
    button.disabled = true;
    button.setAttribute('aria-busy', 'true');


    try {
      // Use Rails' request.js for fetch with CSRF handling
      const request = new FetchRequest('get', lookupUrl, { responseKind: 'json' })
      const response = await request.perform()

      if (response.ok) {
        const data = await response.json;
        console.log("Received data from Rails:", data); // For debugging

        if (data.error) {
          throw new Error(data.error);
        }

        // Populate fields based on the JSON response from our Rails action
        this.populateField("title", data.title);
        this.populateField("author", data.author); // Expecting pre-formatted string from Rails
        this.populateField("genre", data.genre);   // Expecting pre-formatted string from Rails
        this.populateField("publisher", data.publisher); // Expecting pre-formatted string from Rails
        this.populateField("publicationDate", data.publication_date);
        this.populateField("pageCount", data.page_count);
        this.populateField("description", data.description); // Optional

        this.setStatus("Data populated!", "success");
      } else {
        // Handle non-OK responses (like 404 from our Rails action)
        const errorData = await response.json; // Try to get error message from Rails JSON response
        throw new Error(errorData?.error || `Lookup failed: ${response.statusCode}`);
      }

    } catch (error) {
      console.error("ISBN Lookup Error:", error);
      this.setStatus(`Error: ${error.message}`, "error");
    } finally {
      // Re-enable button
      button.disabled = false;
      button.removeAttribute('aria-busy');
      // Optional: Clear status after a few seconds
      setTimeout(() => this.setStatus(''), 5000);
    }
  }

  // Helper to safely populate fields only if the target exists
  populateField(targetName, value) {
    // Stimulus creates has<TargetName>Target properties
    if (this[`has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`] && value !== undefined && value !== null) {
      this[`${targetName}Target`].value = value;
    }
  }

  // Helper to update the status message
  setStatus(message, type = "info") {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message;
      // Add Pico style hints via data attributes or classes if desired
      this.statusTarget.dataset.statusType = type; // e.g., style with CSS [data-status-type="error"] { color: red; }
    }
  }
}
