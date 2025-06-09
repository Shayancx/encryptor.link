import "./application.css";
import { Application } from "@hotwired/stimulus";
import EncryptionController from "./controllers/encryption_controller";
import ThemeController from "./controllers/theme_controller";
import RichEditorController from "./controllers/rich_editor_controller";
import RateLimitController from "./controllers/rate_limit_controller";
import DataTableController from "./controllers/data_table_controller";
import "./lib/csrf-helper";

declare global {
  interface Window {
    Stimulus: Application;
  }
}

window.Stimulus = Application.start();
window.Stimulus.register("encryption", EncryptionController);
window.Stimulus.register("theme", ThemeController);
window.Stimulus.register("rich-editor", RichEditorController);
window.Stimulus.register("rate-limit", RateLimitController);
window.Stimulus.register("data-table", DataTableController);
