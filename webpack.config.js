var webpack = require('webpack'),
    path = require('path');

config = {

  entry: {
    franklin: './@client/franklin.coffee'
  },

  output: {
    path: './public/build',
    filename: "[name].js"
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

module.exports = config