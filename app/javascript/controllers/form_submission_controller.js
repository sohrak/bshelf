import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-submission"
export default class extends Controller {
  connect() {
    // Optional: Log connection for debugging
    // console.log("Form submission controller connected", this.element)
  }

  submit() {
    // Debounce submission to avoid rapid firing on select changes etc.
    clearTimeout(this.submitTimeout)
    this.submitTimeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 150) // Adjust delay as needed (e.g., 150ms)
  }

  // Optional: Disconnect logic if needed
  // disconnect() {
  //   clearTimeout(this.submitTimeout)
  // }
}
