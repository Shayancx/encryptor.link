import { Controller } from "@hotwired/stimulus";

export abstract class BaseController extends Controller {
  private cleanupFunctions: Array<() => void> = [];
  private activeRequests: Map<string, AbortController> = new Map();

  protected safeQuerySelector<T extends Element>(
    selector: string,
    parent: Element | Document = document
  ): T | null {
    try {
      return parent.querySelector<T>(selector);
    } catch (error) {
      console.error(`Failed to query selector: ${selector}`, error);
      return null;
    }
  }

  protected safeQuerySelectorAll<T extends Element>(
    selector: string,
    parent: Element | Document = document
  ): NodeListOf<T> {
    try {
      return parent.querySelectorAll<T>(selector);
    } catch (error) {
      console.error(`Failed to query selector: ${selector}`, error);
      return document.querySelectorAll<T>('never-match');
    }
  }

  protected addManagedEventListener(
    element: Element | Window | Document | null,
    event: string,
    handler: EventListener,
    options?: boolean | AddEventListenerOptions
  ): void {
    if (!element) return;
    
    element.addEventListener(event, handler, options);
    this.cleanupFunctions.push(() => 
      element.removeEventListener(event, handler, options)
    );
  }

  protected async makeRequest(
    key: string,
    requestFn: () => Promise<Response>
  ): Promise<Response> {
    // Cancel any existing request with the same key
    this.cancelRequest(key);

    // Create new abort controller
    const abortController = new AbortController();
    this.activeRequests.set(key, abortController);

    try {
      const response = await requestFn();
      return response;
    } finally {
      this.activeRequests.delete(key);
    }
  }

  protected cancelRequest(key: string): void {
    const controller = this.activeRequests.get(key);
    if (controller) {
      controller.abort();
      this.activeRequests.delete(key);
    }
  }

  protected cancelAllRequests(): void {
    this.activeRequests.forEach(controller => controller.abort());
    this.activeRequests.clear();
  }

  protected hasTargetElement(name: string): boolean {
    const targetName = `has${name.charAt(0).toUpperCase() + name.slice(1)}Target`;
    return (this as any)[targetName] || false;
  }

  protected getTargetElement<T extends Element>(name: string): T | null {
    if (!this.hasTargetElement(name)) return null;
    const targetName = `${name}Target`;
    return (this as any)[targetName] as T;
  }

  protected getTargetElements<T extends Element>(name: string): T[] {
    const targetName = `${name}Targets`;
    return (this as any)[targetName] || [];
  }

  protected validateState(): boolean {
    // Override in subclasses to validate component state
    return true;
  }

  protected showError(message: string): void {
    console.error(`[${this.constructor.name}] ${message}`);
    // Could also dispatch a custom event for global error handling
    this.dispatch('error', { detail: { message } });
  }

  disconnect(): void {
    // Cancel all pending requests
    this.cancelAllRequests();
    
    // Run all cleanup functions
    this.cleanupFunctions.forEach(cleanup => {
      try {
        cleanup();
      } catch (error) {
        console.error('Cleanup function error:', error);
      }
    });
    this.cleanupFunctions = [];

    // Call parent disconnect if it exists
    if (super.disconnect) {
      super.disconnect();
    }
  }
}
