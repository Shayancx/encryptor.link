import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["sun", "moon"];

  connect() {
    const userPrefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    const savedTheme = localStorage.getItem('theme');
    this.currentTheme = savedTheme || (userPrefersDark ? 'dark' : 'light');
    document.documentElement.setAttribute('data-bs-theme', this.currentTheme);
    this.updateIcons();
  }

  toggle() {
    this.currentTheme = this.currentTheme === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-bs-theme', this.currentTheme);
    localStorage.setItem('theme', this.currentTheme);
    this.updateIcons();
  }

  updateIcons() {
    if (!this.hasSunTarget || !this.hasMoonTarget) return;
    if (this.currentTheme === 'dark') {
      this.moonTarget.style.display = 'block';
      this.sunTarget.style.display = 'none';
    } else {
      this.sunTarget.style.display = 'block';
      this.moonTarget.style.display = 'none';
    }
  }
}
