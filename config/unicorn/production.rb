
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 15
preload_app true

app_path = File.join(File.dirname(__FILE__), '../..')
listen File.join(app_path, 'tmp/sockets/unicorn.sock')
pid File.join(app_path, 'tmp/pids/unicorn.pid')
stderr_path File.join(app_path, 'log/unicorn.stderr.log')
stdout_path File.join(app_path, 'log/unicorn.stdout.log')

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

# Not using ActiveRecord (yet)
#  defined?(ActiveRecord::Base) and
#    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

# Not using ActiveRecord (yet)
#  defined?(ActiveRecord::Base) and
#    ActiveRecord::Base.establish_connection
end
