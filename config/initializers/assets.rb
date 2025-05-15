# Be sure to restart your server when you modify this file.

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("app/assets/fonts")

# Precompile additional assets.
Rails.application.config.assets.precompile += %w[ application.bootstrap.scss ]
