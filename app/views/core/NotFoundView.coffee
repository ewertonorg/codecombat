RootView = require 'views/core/RootView'
template = require 'templates/not_found'

module.exports = class NotFoundView extends RootView
  id: 'not-found-view'
  template: template
