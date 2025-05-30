# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "popper", to: "popper.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "encrypt", to: "/encrypt.js"
pin "decrypt", to: "/decrypt.js"
pin "account_ui", to: "account_ui.js"

# Rich text editor (fixed the duplicated and conflicting imports)
