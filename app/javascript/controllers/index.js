// Import and register all your controllers from the importmaps under controllers/*

import { application } from "../controllers/application"

// Eager load all controllers defined in the import map
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import RateLimitController from "../controllers/rate_limit_controller"
application.register("rate-limit", RateLimitController)
eagerLoadControllersFrom("controllers", application)
import RateLimitController from "../controllers/rate_limit_controller"
application.register("rate-limit", RateLimitController)
