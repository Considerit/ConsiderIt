///////////
// Webpack.config.js
//
// TODO: document


var webpack = require('webpack'),
    path = require('path'), 
    is_dev = !JSON.parse(process.env.BUILD_PRODUCTION || 'false');


console.log("BUILDING FOR " + (is_dev ? "DEVELOPMENT" : "PRODUCTION"))

config = {

  debug : is_dev,
  displayErrorDetails : true,
  outputPathinfo : true,
  devtool : is_dev ? 'eval' : 'sourcemap',

  entry: {
    franklin: './@client/franklin.coffee'
  },

  output: { 
    path: './public/build',
    filename: is_dev ? "[name].js" : "[name].[chunkhash].js"
  },

  module: {
    loaders: [
      { test: /\.coffee$/, loader: 'coffee-loader' },
    ],
    noParse: [
      /react\.js$/, 
      /jquery\.js$/,       
      /quill\.js$/
    ]

  },

  resolve: {
    root: [__dirname, '@client'].join('/'),
    extensions: ['', '.js', '.json', '.coffee'] 
  },


  plugins: [
    new webpack.DefinePlugin({ 
        // Each instance of a key will be replaced with the 
        // value in the build.
      __DEV__: is_dev,
      __PRODUCTION__: !is_dev
    }),

    new webpack.ProvidePlugin({
        '_': "vendor/underscore",
        $: "vendor/jquery",
        jQuery: "vendor/jquery",
        React: "vendor/react"
    }),

    // Create a public/build/manifest.json file
    function() {
      this.plugin("done", function(stats) {
        manifest = {}
        for (var prop in config.entry){
          file = stats.toJson().assetsByChunkName[prop]
          if (typeof file !== 'string')
            file = file[0]
          manifest[prop] = path.join("build", file)
        }
        require("fs").writeFileSync(
          path.join(__dirname, "public", "build", "manifest.json"),
          JSON.stringify(manifest));
      });
    }

  ]

}

if(!is_dev){
  var s3 = require('s3'),
      YAML = require('yamljs')

  config.plugins.push(
    new webpack.optimize.UglifyJsPlugin(),
    new webpack.optimize.OccurenceOrderPlugin(),

    // write to S3
    function() {
      this.plugin("done", function(stats) {

        local = YAML.load('config/local_environment.yml').default

        var client = s3.createClient({
          s3Options: {
            accessKeyId: local.aws.access_key_id,
            secretAccessKey: local.aws.secret_access_key,
          },
        })

        var upload = function(src, dest) {

          var uploader = client.uploadDir({
            localDir: src,
            deleteRemoved: false, // remove s3 objects that have 
                                  // no corresponding local file. 
            s3Params: {
              Bucket: local.aws.s3_bucket,
              Prefix: dest,
            },
          })

          uploader.on('start', function() {
            console.log('*******/nUploading ' + src + ' to ' + dest + '\n*******')
          })

          uploader.on('error', function(err) {
            console.error("unable to sync:", err.stack)
          })
          uploader.on('progress', function() {
            console.log("progress", uploader.progressAmount, uploader.progressTotal)
          })
          uploader.on('end', function() {
            console.log("done uploading")
          })


        }

        upload( 'public/build', 'build')
        upload( 'public/images', 'images')

      })
    }    
  )
}

module.exports = config