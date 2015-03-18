var webpack = require('webpack'),
    path = require('path')
    config = require('./webpack.config.js');

config.debug = true,
config.displayErrorDetails = true
config.outputPathinfo = true
config.devtool = 'sourcemap'

// config.plugins.push(
//   new webpack.optimize.CommonsChunkPlugin('common', 'common-[chunkhash].js'),
// );

module.exports = config