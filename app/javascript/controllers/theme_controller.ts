import { BaseController } from "./base/BaseController";

interface ThemeTargets {
  sun: SVGElement;
  moon: SVGElement;
}

export default class extends BaseController {
  static targets = ["sun", "moon"];
  
  declare readonly hasSunTarget: boolean;
  declare readonly hasMoonTarget: boolean;
  declare readonly sunTarget: SVGElement;
  declare readonly moonTarget: SVGElement;

  private currentTheme: string = 'light';

  connect(): void {
    const userPrefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    const savedTheme = localStorage.getItem('theme');
    this.currentTheme = savedTheme || (userPrefersDark ? 'dark' : 'light');
    this.applyTheme();
    this.updateIcons();

    // Listen for system theme changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    this.addManagedEventListener(mediaQuery, 'change', (e: MediaQueryListEvent) => {
      if (!localStorage.getItem('theme')) {
        this.currentTheme = e.matches ? 'dark' : 'light';
        this.applyTheme();
        this.updateIcons();
      }
    });
  }

  toggle(): void {
    this.currentTheme = this.currentTheme === 'dark' ? 'light' : 'dark';
    this.applyTheme();
    localStorage.setItem('theme', this.currentTheme);
    this.updateIcons();
    this.dispatch('theme-changed', { detail: { theme: this.currentTheme } });
  }

  private applyTheme(): void {
    document.documentElement.classList.toggle('dark', this.currentTheme === 'dark');
  }

  private updateIcons(): void {
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
