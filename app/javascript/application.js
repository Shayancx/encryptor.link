import { Application } from "@hotwired/stimulus";
import EncryptionController from "./controllers/encryption_controller";
import ThemeController from "./controllers/theme_controller";
import RichEditorController from "./controllers/rich_editor_controller";

window.Stimulus = Application.start();
Stimulus.register("encryption", EncryptionController);
Stimulus.register("theme", ThemeController);
Stimulus.register("rich-editor", RichEditorController);
