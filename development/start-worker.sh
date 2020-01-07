#!/bin/bash
FAKTORY_PROVIDER=FAKTORY_URL FAKTORY_URL=tcp://:afd65d8e460c228a@localhost:7419 bundle exec faktory-worker -r ./text-track-worker.rb
