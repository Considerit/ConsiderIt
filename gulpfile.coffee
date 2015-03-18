gulp       = require "gulp"
source_map = require "gulp-sourcemaps"
filter     = require "gulp-filter"
coffee     = require "gulp-coffee"
concat     = require "gulp-concat"
rev        = require "gulp-rev-all"
insert     = require "gulp-insert"

gulp.task "default", ["compile_javascript", "images", "cache_bust"]



coffee_filter = filter ["**/*.coffee"]

gulp.task "compile_javascript", ->
  gulp.src "@client/**/*.{js,coffee}" #todo: handle ERB
    .pipe coffee_filter
    .pipe coffee()
    .pipe coffee_filter.restore()
    .pipe concat "application.js"
    .pipe gulp.dest "public/assets"


gulp.task "images", ->
  gulp.src "@client/images/**/*"
    .pipe gulp.dest "public/assets/images/"


gulp.task "cache_bust", ['images', 'compile_javascript'], ->
  gulp.src ["public/*assets/**"]
    .pipe rev()
    .pipe gulp.dest "public"
    .pipe rev.manifest()
    .pipe gulp.dest "public/assets"






# gulp.task "reload", ["watch", "js", "images"] #, "fonts"]


# gulp.task "watch", ->
#   liveReload.listen
#   gulp.watch "@client",  { interval: 500 }, ["js"]


# gulp.task "js", ->
#   gulp.src("@client/*.coffee")

#     .pipe(gulp.dest("public/assets"))


    # # .pipe(sourceMaps.init())
    # .pipe(coffeeFilter)
    # .pipe(coffee())
    # .pipe(coffeeFilter.restore())
    # # .pipe(concat("application.js"))
    # # .pipe(sourceMaps.write("."))
    # .pipe(gulp.dest("public/assets"))
    # #.pipe(liveReload())


# gulp.task "fonts", ->
#   gulp.src("fonts/**/*")
#     .pipe(gulp.dest("../public/assets/fonts/"))
#     .pipe(liveReload())
