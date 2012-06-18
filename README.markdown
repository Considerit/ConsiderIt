# ConsiderIt

ConsiderIt is an open source deliberation platform that allows people
to collaboratively create pro/con lists of the key points around any
complex issue.

ConsiderIt works by drawing on the wisdom of crowds to generate a set
of key considerations for decision-making: helping organizations
identify the pro and con points that matter most to their users,
readers or constituents.

ConsiderIt helps individuals make sense of complex issues by letting
them create pro/con lists of the key points that matter to
them. ConsiderIt makes it easy to endorse points made by others who
share your views, or to add new points of your own.

ConsiderIt also helps create common ground among people with different
views.  ConsiderIt prioritizes the pro and con points that are
endorsed by people from across the decision spectrum, decreasing
polarization and helping decision-makers move towards solutions with
broad appeal.

ConsiderIt is an open source Ruby on Rails project. It is licensed
under the AGPL.


## Installation

Here are installation instructions, along with some hints in case of
problems (mostly Macintosh-specific).


* Manage ruby / rails installs with
  [RVM](https://rvm.beginrescueend.com/gemsets/).  After installing
  rvm, install ruby 1.93:

          rvm install 1.9.3

  Good mac install
  directions
  [here](http://www.cowboycoded.com/2010/12/04/setting-up-rails-3-on-mac-osx-snow-leopard-10-6-4/).
  You can use RVM to install Ruby in a personal directory or in the
  system directory.  Personal directory is recommended in any case;
  for linux this is also useful if you don't have root access.  On
  the Mac, RVM will install a recent version of Ruby, but also leave
  the built-in version of Ruby intact at <tt>/usr/bin/ruby</tt>.

  The suggested script for installing rvm is:

          bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)

  If this doesn't work, try downloading and saving the script,
  and running it directly as a shell script.
  After you're done, check that you have the correct version of ruby
  (should be 1.9.3):

          ruby -v

  Set this as the default in RVM so you don't have to switch each time
  you open a new shell:

          rvm --default use 1.9.3

* Clone from git repository into your workspace using the following command.
  Note that you will have to set up your ssh keys with github first
  (see [github linux setup](http://help.github.com/linux-set-up-git/)).

          git clone git@github.com:tkriplean/ConsiderIt.git

* Go into the ConsiderIt directory:

          cd ConsiderIt

  An RVM project file (.rvmrc) already exists in the project.  When
  you first cd into the directory, RVM should recognize this and ask
  if you trust it.  You should say yes.

* Install a SQL database if needed.  We've been using 
  [MySQL](http://dev.mysql.com/downloads/).

* Install [ImageMagick](http://www.imagemagick.org/script/index.php).
  For the Macintosh the recommended technique is to use
  [MacPorts](http://www.macports.org/).  This involves building from
  source and takes a while -- no dmg file, unfortunately.  However,
  this has worked fine on various Macs, so you probably won't have
  any trouble.

* Install gems.  First deal with the problematic <tt>mysql</tt> gem
  (at least it's problematic on the mac and ubuntu 11.04); and then install everything
  else.  To install the mysql gem on the Mac, first try this:

          sudo env ARCHFLAGS="-arch x86_64" gem install mysql -with-mysql-config=/usr/local/mysql/bin/mysql_config

  Or with MAMP:

          sudo env ARCHFLAGS="-arch x86_64" gem install mysql -with-mysql-config=/Applications/MAMP/Library/bin/mysql_config

  accessing MAMP mysql via terminal: 

          mysql --socket=/Applications/MAMP/tmp/mysql/mysql.sock -u root -p
          
  To install the mysql gem on Ubuntu remove the socket from config/database.yml. 
  Make sure that the you have created the password in config/database.yml for
  the user and hostname that you have specified. When the host is not specified in
  the Ubuntu version of mysql it does not default to 'localhost'.
  

  Now install the other gems.  The Gemfile in the ConsiderIt
  directory specifies a particular version of rails, so specify that.

          gem install rails -v '3.0.6'
          bundle install

  As noted, the mysql gem is problematic on the
  Macintosh.  The mysql2 gem is touted as superior to the mysql gem, so
  you can try that if the instructions above don't work.  However, the
  most recent version of mysql2 didn't install correctly.  Installing an older
  version (0.2.7) worked on a Macbook air running Snow Leopard (version
  10.6.8).  You'll first need to fix a path problem for Ruby mysql2 gem
  to find the correct library by putting this in your .profile file:

          export DYLD_LIBRARY_PATH="/usr/local/mysql/lib:$DYLD_LIBRARY_PATH"

  Then this should install the gem itself:

          sudo env ARCHFLAGS="-arch x86_64" gem install mysql2 -v 0.2.7 -- --with-mysql-config=/usr/local/mysql/bin/mysql_config

  If you use mysql2 rather than mysql, edit the Gemfile by replacing
  this line: <tt>gem 'mysql'</tt> with 

          gem 'mysql2', '0.2.7'

  Also replace mysql (the adaptor) in <tt>config/database.yml</tt>
  with mysql2.

  Neither of these techniques worked on a desktop Mac Pro running
  Leopard (version 10.5.8).  There were various problems, including not
  being able to find the library.  To get this working I ended up
  removing the version of mysql installed from the dmg file and
  installed it using Macports.  (There must be a better way but this
  worked.)  Here are directions for completely removing MySQL if you end
  up needing to do this:
  [http://akrabat.com/computing/uninstalling-mysql-on-mac-os-x-leopard/](http://akrabat.com/computing/uninstalling-mysql-on-mac-os-x-leopard/)

  Then install MySQL using Macports:

          sudo port install mysql5
          sudo port install mysql5-server

  After this, a simple

          sudo gem install mysql

  worked.

* Update <tt>config/database.yml</tt> as necessary.  If you used the
  mysql2 gem, you'll need to change the adaptor accordingly.  Also
  edit the user name or password to taste.

* Create the database

          rake db:create
          rake db:migrate
  
  On Ubuntu 11.04 create fails with an error saying that it cannot find the 
  Javascript runtime. If you get this error install node.js from 
  
          https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager

  On Ubuntu 11.04 you will also come accross the error "rake aborted! stack level too deep". 
  To fix this run these commands instead:
          bundle exec rake db:create
          bundle exec rake db:migrate

* Start the web server:

          rails server

  (run with <tt>--help</tt> for options)

* (optional) Deployment
    * When creating app on heroku, specify 1.9.2 stack: http://devcenter.heroku.com/articles/stack
    * You can have multiple remote sites for git, such as github and heroku: http://devcenter.heroku.com/articles/git
    * When deploying in production mode, you need to precompile the assets, such as with '> rake assets:precompile -e production'

* More Troubleshooting.  If you are still having trouble with rails
  or with the mysql interface, try making a trivial test application
  with rails, as described
  [here](http://www.cowboycoded.com/2010/12/04/setting-up-rails-3-on-mac-osx-snow-leopard-10-6-4/)

          rails new test_app
          cd test_app
          bundle install
          rails s

  Then point a browser to <tt>http://localhost:3000</tt> and see if it works.
  Be sure and click the "About your application’s environment" link
  as part of the test since that queries the database.

  This first version of the test application uses the built-in
  database sqlite3.  If this works, next try using mysql -- change
  the Gemfile to use mysql (or mysql2) rather than sqlite, and also
  edit config/database.yml to use mysql as well.  Run "bundle
  install" again and start up rails -- if things still work then you
  know that rails and the mysql gem are OK and the problem is
  elsewhere.