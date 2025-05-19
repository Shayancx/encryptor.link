// Entry point for the build script in your package.json
import "@hotwired/stimulus"
import "./controllers"
import "trix"
import "@rails/actiontext"

// Custom Trix configuration
document.addEventListener("trix-initialize", function(event) {
  // To preserve the content formatting when encrypting and decrypting
  const trixEditor = event.target;

  // Additional configuration can be added here
});

console.log("Encryptor.link application loaded!");
