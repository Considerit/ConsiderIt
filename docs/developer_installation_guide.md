Getting started for local development
-------------------------------------

This installation guide is written for development on Ubuntu, and has been tested on Ubuntu 12.04 and 14.04. 

### Upgrade system & install dependencies

```
sudo apt-get update
sudo apt-get -y upgrade
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -y install advancecomp autoconf automake bison build-essential \
     curl emacs23-nox exuberant-ctags gifsicle git-core imagemagick \
     jpegoptim libcurl4-openssl-dev libjpeg-progs libmagickcore-dev \
     libmagickwand-dev libmysqlclient-dev libreadline6 libreadline6-dev \
     libreadline-dev libssl-dev libncurses5-dev libtool libxml2-dev \
     libxslt1-dev memcached mysql-server openssl optipng nodejs npm \
     pngcrush python-apt python-pip python-mysqldb unattended-upgrades \
     unzip zlib1g zlib1g-dev
sudo ln -s /usr/bin/nodejs /usr/bin/node
```

The non-interactive prompt prevents mysql-server from asking for a root password to your database. We'll set that later. 

### Install Ruby
```
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
echo 'eval "$(rbenv init -)"' >> ~/.profile
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.profile
source ~/.profile
rbenv install -v 2.2.2
rbenv global 2.2.2
gem install bundler --no-rdoc --no-ri
```

You can probably install a more recent version of Ruby. I just haven't tested it with required gems. 


### Configure mysql 

```
service mysql restart
mysqladmin -u root password root
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

You'll want to have webpack watching in the background for changes to your javascript.

```
bin/webpack &
```

Then start your rails server:

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


### Development enviroments used

I've run considerit in an Ubuntu VM on my Mac, managed by Vagrant and provisioned by Ansible. I also have run it on my Mac.
