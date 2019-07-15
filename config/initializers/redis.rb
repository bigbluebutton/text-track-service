require 'yaml'

props = YAML::load(File.open('settings.yaml'))
redis_host = props['redis_host']
redis_port = props['redis_port']
redis_password = props['redis_password']

puts "REDIS HOST=#{redis_host} PORT=#{redis_port} PASS=#{redis_password}"

redis_namespace = props["redis_list_namespace"]

# Namespace our keys to bbb_texttrack_service:<whatever>
# $redis.lpush("foo", "bar") is really bbb_texttrack_service:foo
# $redis.llen("foo") is really bbb_texttrack_service:foo
$redis = Redis::Namespace.new(redis_namespace, :redis => Redis.new)
