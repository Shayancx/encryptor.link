# Pagy initializer
require "pagy/extras/bootstrap"
require "pagy/extras/array"
require "pagy/extras/overflow"

# Set Pagy defaults
Pagy::DEFAULT[:items] = 5        # Items per page
Pagy::DEFAULT[:size]  = [ 1, 4, 4, 1 ] # Navigation size
Pagy::DEFAULT[:overflow] = :last_page # Handle overflows
