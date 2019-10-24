#!/bin/bash
FAKTORY_PROVIDER=FAKTORY_URL FAKTORY_URL=tcp://:parthik@localhost:7419 bundle exec faktory-worker -r ./text-track-worker.rb
