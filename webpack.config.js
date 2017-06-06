///////////
// Webpack.config.js
//
// Uses Webpack to build our javascript assets. Creates source maps
// as well.
//
// All considerit servers serve javascript compiled through this 
// script, both dev and production. 
//
// In development, you can have Webpack watch for changes so that the
// compilation is automatic: 
//    > node_modules/webpack/bin/webpack.js --progress --colors --watch
//    (shortcut:   >  bin/webpack )
//
// To compile for production, set the environment variable 
//      BUILD_PRODUCTION
//
// In production, if we're using a remote asset host like Cloudfront, 
// this will also upload the built javascript (and images) to the configured
// host. 
// 
// This process replaces Rails' asset pipeline.


///////////////////////
// Input
// 
// These variables are pulled out because they're most likely to be configured
// as part of writing an application.


var fs = require('fs')


/////
// Entry points
// These are the different entry points to the application that will be 
// compiled. All required files starting from the entry point will be compiled
// into the respective build. 
entry_points = {
  franklin: './@client/franklin.coffee',
  proposal_embed: './@client/proposal_embed.coffee'
}

////////////////////////////////////////
// Innards

var webpack = require('webpack'),
    path = require('path'), 
    is_dev = !JSON.parse(process.env.BUILD_PRODUCTION || 'false'),
    directory = __dirname;

config = {

  debug : is_dev,
  displayErrorDetails : true,
  outputPathinfo : true,
  devtool : is_dev ? 'cheap-eval-source-map' : 'source-map',

  entry: entry_points,

  // We output build javascript to public/build. 
  // A cache-busting digest is appended when we're in production
  output: { 
    path: './public/build',
    filename: is_dev ? "[name].js" : "[name].[chunkhash].js"
  },

  module: {

    // Enables compilation of coffee into javascript
    loaders: [
      { test: /\.coffee$/, loader: 'coffee-loader', include: path.resolve(__dirname, "@client") },
    ],

  },

  resolve: {
    root: [directory, '@client'].join('/'),
    extensions: ['', '.js', '.json', '.coffee'] 
           // don't have to specify .js etc in requires statements
  },


  plugins: [

    ///////////////
    // DefinePlugin
    //
    // Each instance of a key will be replaced with the 
    // value in the build.  
    new webpack.DefinePlugin({ 
      __DEV__: is_dev,
      __PRODUCTION__: !is_dev
    }),

    ////////////
    // Creates a public/build/manifest.json file that maps from
    // each entry point to the compiled version of it. Useful in 
    // particular when the compiled filename includes a digest 
    function() {
      this.plugin("done", function(stats) {
        manifest = {}
        
        for (var prop in config.entry){
          if(prop){
            file = stats.toJson().assetsByChunkName[prop]
            if (file && typeof file !== 'string')
              file = file[0]

            if (file) {
              manifest[prop] = path.join("build", file)
            } else {
              console.log("BAD FILE", prop, stats.toJson().assetsByChunkName)
            }
          }
        }
        require("fs").writeFileSync(
          path.join(directory, "public", "build", "manifest.json"),
          JSON.stringify(manifest));
      });
    }
  ]
}

/////
// Additional work when we're compiling for production
if(!is_dev){

  var s3 = require('s3'),
      YAML = require('yamljs'),
      CompressionPlugin = require("compression-webpack-plugin")

  config.plugins.push(

    //////
    // Uglify
    // Further compression. Unexpectedly cuts gzipped main js file size in half.
    // This is the slowest part of the process of building.
    new webpack.optimize.UglifyJsPlugin(),

    new webpack.optimize.OccurenceOrderPlugin(),

    //////
    // Compression
    // Gzip the js/sourcemaps coming through the pipeline. Note that the file 
    // extension doesn't change. Web servers need to have Content-Encoding gzip 
    // set for these files. 
    new CompressionPlugin({
        asset: "{file}",
        algorithm: "gzip"
    }),

    /////////
    // Upload to s3 (and as a consequence, Cloudfront)
    //
    // Finally we'll upload these compiled js/source maps to s3, along with 
    // syncing the public/images directory. 
    function() {
      this.plugin("done", function(stats) {

        local = YAML.load('config/local_environment.yml').default
        if (!local.aws) return // do nothing if aws isn't configured

        var s3_client = s3.createClient({
            s3Options : {
              accessKeyId: local.aws.access_key_id,
              secretAccessKey: local.aws.secret_access_key,
            }})

        // Syncs a directory from this host to s3. 
        // set is_gzipped if you want to set the Content-Encoding to gzip for all
        // files in this directory. 
        var uploadDir = function(src, dest, is_gzipped) {

          s3_params = {
            Bucket: local.aws.s3_bucket,
            Prefix: dest,
            Expires: new Date(new Date().setYear(new Date().getFullYear() + 1)),
            CacheControl: 'public, max-age=31557600'
          }

          if (is_gzipped)
            s3_params.ContentEncoding = 'gzip'

          var uploader = s3_client.uploadDir({
            localDir: src,
            deleteRemoved: false, // remove s3 objects that lack 
                                  // a corresponding local file. 
            s3Params: s3_params
          })

          uploader.on('error', function(err) {
            console.error("unable to sync:", err.stack)
          })
          uploader.on('end', function() {
            console.log("done uploading")
          })
          uploader.on('fileUploadEnd', function(path, key) {
            console.log("UPLOADED ", path)
          })
        }

        // sync js
        uploadDir( 'public/build', 'build', true)

        // sync images
        uploadDir( 'public/images', 'images')

        // sync embedding
        uploadDir( 'public/embedding', 'embedding')

        // sync embedding
        uploadDir( 'public/vendor', 'vendor')


      })
    }    
  )
}

console.log("BUILDING FOR " + (is_dev ? "DEVELOPMENT" : "PRODUCTION"))
module.exports = config