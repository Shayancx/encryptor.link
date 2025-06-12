namespace :cleanup do
  desc "Clean up expired encrypted payloads and files"
  task expired: :environment do
    CleanupExpiredFilesJob.perform_now
  end
end
