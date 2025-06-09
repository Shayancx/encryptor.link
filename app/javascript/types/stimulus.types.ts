import { Controller } from "@hotwired/stimulus";

export interface StimulusTargets {
  readonly [key: string]: Element | null;
}

export interface StimulusController<T extends StimulusTargets> extends Controller {
  readonly targets: T;
  connect(): void;
  disconnect(): void;
}

export interface TargetProperties {
  hasTarget(name: string): boolean;
  [key: `has${string}Target`]: boolean;
  [key: `${string}Target`]: Element;
  [key: `${string}Targets`]: Element[];
}
