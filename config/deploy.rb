# Settings

# set deployment stages
set :stages, %w(production staging dev)
set :default_stage, "staging"

# SSH settings
set :domain,  "example.com"
set :user,    "exampleuser"

# Application settings
set :application, "application"
# set :www_user, "www-data"

set :copy_exclude, ["Capfile", "config", ".git", ".gitignore", ".gitmodules", "wp-config.php"]
set :repository, "git@github.com:example/example.git"
set :scm, :git
set :branch, "master"
set :scm_verbose, false
set :git_enable_submodules, 1

server "#{domain}", :app, :web, :db, :primary => true

set :deploy_via, :remote_cache
set :use_sudo, false
set :keep_releases, 5
ssh_options[:paranoid] = false
ssh_options[:forward_agent] = true

# Wordpress specific methods
after 'deploy:setup', 'wordpress:setup'
after 'deploy:symlink', 'wordpress:symlink'
before 'deploy:cleanup', 'wordpress:permission_fix'

namespace :wordpress do
  desc <<-DESC
  symlinks shared files dirs
  DESC
  task :symlink, :except => { :no_release => true } do
    run "ln -s #{shared_path}/uploads #{latest_release}/wp-content/uploads"
    run "ln -s #{latest_release}/wp-config-#{stage}.php #{latest_release}/wp-config.php"
  end

  desc <<-DESC
  fixes permissions so old deploys can be deleted
  DESC
  task :permission_fix, :except => { :no_release => true } do
    count = fetch(:keep_releases, 5).to_i
    if count >= releases.length
      logger.info "no permissions to fix"
    else
      logger.info "fixing permissions"

      directories = (releases - releases.last(count)).map { |release|
        File.join(releases_path, release) }.join(" ")

      run "chmod -R +w #{directories}"
    end
  end

  desc <<-DESC
  creates shared wordpress directories
  DESC
  task :setup do
    run "mkdir -p #{shared_path}/uploads"
  end
end

namespace :password_protect do
  task :symlink, :except => { :no_release => true } do
    # We keep a local copy of the .htaccess on the server because we have htpasswd to worry about
    logger.info "linking .htaccess"
    run "rm -f #{latest_release}/.htaccess"
    run "ln -s #{shared_path}/htaccess #{latest_release}/.htaccess"
  end
end

# this tells capistrano what to do when you deploy
namespace :deploy do

  desc <<-DESC
  A macro-task that updates the code and fixes the symlink.
  DESC
  task :default do
    transaction do
      update_code
      symlink
    end
  end

  task :update_code, :except => { :no_release => true } do
    on_rollback { run "rm -rf #{release_path}; true" }
    strategy.deploy!
  end

  after 'deploy' do
    cleanup
  end
end
