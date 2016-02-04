Consider.it
===========

[Consider.it][1] is a deliberation and opinion visualization tool for focused
discussion on the web.

[1]: <https://consider.it>

The creator and maintainer is [Travis Kriplean][2]. Travis runs a business based
on Consider.it under the umbrella of [Invisible College, LLC][3].

[2]: <tkriplean@gmail.com>

[3]: <https://invisible.college>

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
```

The non-interative prompt prevents mysql-server from asking for a root password to your database. We'll set that later. 

### Install Ruby
```
git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
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

Make sure you have a Github ssh key: https://help.github.com/articles/generating-an-ssh-key/

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


### Start it up!

From your considerit directory:

```
rails s
```

You might also want to run delayed_job, which processes background jobs like uploaded avatars. Not needed though for most development work: 

```
rails s
```

### Other development environments

I run considerit in an Ubuntu VM on my Mac, managed by Vagrant and provisioned by Ansible. Shoot me an email at travis@consider.it if you want to do the same. 