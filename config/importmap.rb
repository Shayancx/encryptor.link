# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "popper", to: "popper.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "encrypt", to: "/encrypt.js"
pin "decrypt", to: "/decrypt.js"

# Rich text editor (fixed the duplicated and conflicting imports)
pin "trix", to: "https://ga.jspm.io/npm:trix@2.0.8/dist/trix.esm.js"
pin "@rails/actiontext", to: "https://ga.jspm.io/npm:@rails/actiontext@7.1.3/app/assets/javascripts/actiontext.esm.js"
