var webpack = require('webpack'),
    path = require('path')
    config = require('./webpack.config.js');


config.output.filename = "[name].[chunkhash].js"
// config.output.chunkFilename = '[id]-bundle-[chunkhash].js'

config.plugins.push(
  // new webpack.optimize.CommonsChunkPlugin('common', 'common-[chunkhash].js'),
  new webpack.optimize.UglifyJsPlugin(),
  new webpack.optimize.OccurenceOrderPlugin(),

  // write to S3
  function() {
    this.plugin("done", function(stats) {
      // copy over images

      // copy over javascript


    });
  }



);

module.exports = config