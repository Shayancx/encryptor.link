// Import and register all your controllers from the importmaps under controllers/*

import { application } from "../controllers/application"

// Eager load all controllers defined in the import map
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
