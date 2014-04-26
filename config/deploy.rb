# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'fiddlybits'
set :repo_url, 'https://github.com/trejkaz/fiddlybits.git'
set :deploy_to, '/var/www/fiddlybits.org'

set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets}

set :default_env, { path: '/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH' }

set :rbenv_type, :system
set :rbenv_ruby, '2.1.1'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end

  after :publishing, :restart

end
