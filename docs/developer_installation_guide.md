Getting started for local development
-------------------------------------

This installation guide is written for development on Ubuntu, and has been tested on Ubuntu 12.04, 14.04, and 22.04.

### Obtain an Ubuntu machine

I've run considerit in an Ubuntu VM on my Mac, managed by Vagrant and provisioned by Ansible. I also have run it directly on my Mac. For development on MacOS, a simple way to get an Ubuntu virtual machine is to install Canonical's Multipass.  Then create and launch the virtual machine:
```
multipass launch --disk 10G
```

### Upgrade system & install dependencies

```
sudo apt-get update
sudo apt-get -y upgrade
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -y install advancecomp autoconf automake bison build-essential \
     curl exuberant-ctags gifsicle git-core imagemagick \
     jpegoptim libcurl4-openssl-dev libjpeg-progs libmagickcore-dev \
     libmagickwand-dev libmysqlclient-dev libreadline6-dev \
     libreadline-dev libssl-dev libncurses5-dev libtool libxml2-dev \
     libxslt1-dev libyaml-dev memcached mysql-server openssl optipng nodejs npm \
     pngcrush python3-apt python-pip python3-mysqldb ruby-build ruby-dev \
     unattended-upgrades unzip zlib1g zlib1g-dev
```

The non-interactive prompt prevents mysql-server from asking for a root password to your database. We'll set that later. 

### Install Ruby
```
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
echo 'eval "$(rbenv init -)"' >> ~/.profile
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.profile
source ~/.profile
rbenv install -v 3.2.2
rbenv global 3.2.2
gem install bundler
```

You can probably install a more recent version of Ruby. I just haven't tested it with required gems.  `gem install` may require several attempts to complete.  If dependency `tomoto` fails to build, it can be manually deleted from Gemfile, since it is not necessary for all development work.


### Configure mysql 

```
sudo service mysql restart
sudo mysqladmin -u root password root
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';"  | sudo mysql
echo "create database considerit_dev;" | mysql -u root -proot
```

We'll use root user/pass here. But you can set it to what you want, as long as you substitute it in in appropriate places, such as config/database.yml (created later in this guide).

### Install considerit

```
git clone https://github.com/tkriplean/ConsiderIt.git considerit
cd considerit
cp config/dev_database.yml config/database.yml
cp config/dev_local_environment.yml config/local_environment.yml
bundle install
npm install
rake db:schema:load
rake db:migrate
```

Note that if you plan on committing a lot of code, you might want to take the time to set up the considerit repository with ssh keys: https://help.github.com/articles/generating-an-ssh-key/. That means using a different git clone protocol as well. 


### Start it up!

Make sure you're in your considerit directory.

You'll want to have webpack watching in the background for changes to your javascript.  Webpack may occasionally freeze and need a restart.

```
bin/webpack &
```

Then start your rails server.  If using a Multipass VM, set flag `--binding` using the IP from `multipass list`.

```
rails s
```

You might also want to have delayed_job running in the background. Delayed_job processes background jobs like uploaded avatars. Not needed though for most development work.

```
bin/delayed_job restart
```

### Make yourself a super_admin

After you make a considerit account for yourself, you'll probably want to make yourself a superadmin. First load the rails console:

```
rails c
```

Then set the field:

```
u=User.find_by_email('my_test@email.address')
u.super_admin=true
u.save
```

Then manually create a forum using mysql:

```
mysql -u root -proot considerit_dev
insert into subdomains (id, name, created_at, updated_at, created_by) values 
( 1, 'MY DOMAIN NAME', now(), now(), (select id from users where email='my_test@email.address') );
quit
```
