# Cron Setup for Cleanup

Add this to your crontab to run cleanup every hour:

```
0 * * * * cd /path/to/encryptor.link && bundle exec rails cleanup:expired
```

Or use whenever gem by adding to schedule.rb:

```ruby
every 1.hour do
  rake "cleanup:expired"
end
```
