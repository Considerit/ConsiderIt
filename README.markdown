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

1. Manage ruby / rails installs with
   [RVM](https://rvm.beginrescueend.com/gemsets/).  After installing
   rvm, install ruby 1.92:

          rvm install 1.9.2

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
   (should be 1.9.2):

          ruby -v

   Set this as the default in RVM so you don't have to switch each time
   you open a new shell:

          rvm --default use 1.9.2

2. Install a SQL database if needed.  We've been using 
   [MySQL](http://dev.mysql.com/downloads/).

3. Clone from git repository into your workspace using the following command.
   Note that you will have to set up your ssh keys with github first
   (see [github linux setup](http://help.github.com/linux-set-up-git/)).

          git clone git@github.com:tkriplean/ConsiderIt.git

4. Install [ImageMagick](http://www.imagemagick.org/script/index.php).
   For the Macintosh the recommended technique is to use
   [MacPorts](http://www.macports.org/).  This involves building from
   source and takes a while -- no dmg file, unfortunately.  However,
   this has worked fine on various Macs, so you probably won't have
   any trouble.

5. Go into the ConsiderIt directory:

          cd ConsiderIt

  An RVM project file (.rvmrc) already exists in the project.  When
  you first cd into the directory, RVM should recognize this and ask
  if you trust it.  You should say yes.

6. Install gems.  First deal with the problematic <tt>mysql</tt> gem
   (at least it's problematic on the mac); and then install everything
   else.  To install the mysql gem on the Mac, first try this:

          sudo env ARCHFLAGS="-arch x86_64" gem install mysql -with-mysql-config=/usr/local/mysql/bin/mysql_config

   Or with MAMP:

          sudo env ARCHFLAGS="-arch x86_64" gem install mysql -with-mysql-config=/Applications/MAMP/Library/bin/mysql_config

   accessing MAMP mysql via terminal: 

          mysql --socket=/Applications/MAMP/tmp/mysql/mysql.sock -u root -p

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

7. Update <tt>config/database.yml</tt> as necessary.  If you used the
   mysql2 gem, you'll need to change the adaptor accordingly.  Also
   edit the user name or password to taste.

8. Create the database

          rake db:create
          rake db:migrate
          rake db:seed

9. Start the web server:

          rails server

   (run with <tt>--help</tt> for options)

10. (optional) Deployment
    * When creating app on heroku, specify 1.9.2 stack: http://devcenter.heroku.com/articles/stack
    * You can have multiple remote sites for git, such as github and heroku: http://devcenter.heroku.com/articles/git


11. More Troubleshooting.  If you are still having trouble with rails
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

12. Updating Measures.  Prior to launch, you can edit the measures
    information by editing the file <tt>ConsiderIt/db/seeds.lvg2.root.rb</tt>.
    After editing the file, you need to rebuild the database.  To do this
    execute

          rake db:reset
          rake db:seed

   The file <tt>ConsiderIt/db/seeds.lvg2.root.rb</tt> was generated from 
   the file <tt>ConsiderIt/lib/tasks/measures.csv</tt> (a big spreadsheet
   of all the measures), using <tt>rake admin:regen_seeds</tt>.
   However, the <tt>seeds.lvg2.root.rb</tt> file has since then been edited
   by hand, so the link with the <tt>csv</tt> file is broken -- if you
   want to make changes, just edit the seeds file.

   **Caution!** Once people have added login information, points, and so
   forth to a running deployment, don't use <tt>rake db:seed</tt> on
   the production system since that will reset the database.  Instead,
   test all the changes on a test version, using the commands above,
   then (painful) make the needed edits to the database on the
   production version to bring it into correspondence with the seeds file.

## Description of Contents

The default directory structure of a generated Ruby on Rails application:

      |-- app
      |   |-- controllers
      |   |-- helpers
      |   |-- mailers
      |   |-- models
      |   `-- views
      |       `-- layouts
      |-- config
      |   |-- environments
      |   |-- initializers
      |   `-- locales
      |-- db
      |-- doc
      |-- lib
      |   `-- tasks
      |-- log
      |-- public
      |   |-- images
      |   |-- javascripts
      |   `-- stylesheets
      |-- script
      |-- test
      |   |-- fixtures
      |   |-- functional
      |   |-- integration
      |   |-- performance
      |   `-- unit
      |-- tmp
      |   |-- cache
      |   |-- pids
      |   |-- sessions
      |   `-- sockets
      `-- vendor
          `-- plugins

    app
      Holds all the code that's specific to this particular application.

    app/controllers
      Holds controllers that should be named like weblogs_controller.rb for
      automated URL mapping. All controllers should descend from
      ApplicationController which itself descends from ActionController::Base.

    app/models
      Holds models that should be named like post.rb. Models descend from
      ActiveRecord::Base by default.

    app/views
      Holds the template files for the view that should be named like
      weblogs/index.html.erb for the WeblogsController#index action. All views use
      eRuby syntax by default.

    app/views/layouts
      Holds the template files for layouts to be used with views. This models the
      common header/footer method of wrapping views. In your views, define a layout
      using the <tt>layout :default</tt> and create a file named default.html.erb.
      Inside default.html.erb, call <% yield %> to render the view using this
      layout.

    app/helpers
      Holds view helpers that should be named like weblogs_helper.rb. These are
      generated for you automatically when using generators for controllers.
      Helpers can be used to wrap functionality for your views into methods.

    config
      Configuration files for the Rails environment, the routing map, the database,
      and other dependencies.

    db
      Contains the database schema in schema.rb. db/migrate contains all the
      sequence of Migrations for your schema.

    doc
      This directory is where your application documentation will be stored when
      generated using <tt>rake doc:app</tt>

    lib
      Application specific libraries. Basically, any kind of custom code that
      doesn't belong under controllers, models, or helpers. This directory is in
      the load path.

    public
      The directory available for the web server. Contains subdirectories for
      images, stylesheets, and javascripts. Also contains the dispatchers and the
      default HTML files. This should be set as the DOCUMENT_ROOT of your web
      server.

    script
      Helper scripts for automation and generation.

    test
      Unit and functional tests along with fixtures. When using the rails generate
      command, template test files will be generated for you and placed in this
      directory.

    vendor
      External libraries that the application depends on. Also includes the plugins
      subdirectory. If the app has frozen rails, those gems also go here, under
      vendor/rails/. This directory is in the load path.
