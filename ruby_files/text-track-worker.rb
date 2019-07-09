require "faktory"

system("FAKTORY_PROVIDER=FAKTORY_URL FAKTORY_URL=tcp://:7832525986eee2f7@localhost:7419 bundle exec faktory-worker -r ./lib/texttrack/google_worker.rb")