CocoView = require 'views/core/CocoView'
template = require 'templates/editor/component/thang-component-config-view'

Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
nodes = require '../level/treema_nodes'

module.exports = class ThangComponentConfigView extends CocoView
  className: 'thang-component-config-view'
  template: template
  changed: false

  constructor: (options) ->
    super options
    @component = options.component
    @config = options.config or {}
    @additionalDefaults = options.additionalDefaults
    @isDefaultComponent = false
    @world = options.world
    @level = options.level
    @callback = options.callback

  getRenderData: (context={}) ->
    context = super(context)
    context.component = @component.attributes
    context.configProperties = []
    context.isDefaultComponent = @isDefaultComponent
    context

  afterRender: ->
    super()
    @buildTreema()

  setConfig: (config) ->
    @handlingChange = true
    @editThangTreema.set('/', config)
    @handlingChange = false

  setIsDefaultComponent: (isDefaultComponent) ->
    changed = @isDefaultComponent isnt isDefaultComponent
    if isDefaultComponent then @config = undefined
    @isDefaultComponent = isDefaultComponent
    @render() if changed

  buildTreema: ->
    thangs = if @level? then @level.get('thangs') else []
    thangIDs = _.filter(_.pluck(thangs, 'id'))
    teams = _.filter(_.pluck(thangs, 'team'))
    superteams = _.filter(_.pluck(thangs, 'superteam'))
    superteams = _.union(teams, superteams)
    schema = $.extend true, {}, @component.get('configSchema')
    schema.default ?= {}
    _.merge schema.default, @additionalDefaults if @additionalDefaults

    if @level?.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']
      schema.required = []
    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: @config
      callbacks: {change: @onConfigEdited}
      world: @world
      view: @
      thangIDs: thangIDs
      teams: teams
      superteams: superteams
      nodeClasses:
        object: ComponentConfigNode
        'point2d': nodes.WorldPointNode
        'viewport': nodes.WorldViewportNode
        'bounds': nodes.WorldBoundsNode
        'radians': nodes.RadiansNode
        'team': nodes.TeamNode
        'superteam': nodes.SuperteamNode
        'meters': nodes.MetersNode
        'kilograms': nodes.KilogramsNode
        'seconds': nodes.SecondsNode
        'speed': nodes.SpeedNode
        'acceleration': nodes.AccelerationNode
        'thang-type': nodes.ThangTypeNode
        'item-thang-type': nodes.ItemThangTypeNode

    @editThangTreema = @$el.find('.treema').treema treemaOptions
    @editThangTreema.build()
    @editThangTreema.open(2)
    if _.isEqual(@editThangTreema.data, {}) and not @editThangTreema.canAddChild()
      @$el.find('.panel-body').hide()

  onConfigEdited: =>
    return if @destroyed or @handlingChange
    @config = @data()
    @changed = true
    @trigger 'changed', { component: @component, config: @config }

  data: -> @editThangTreema.data

  destroy: ->
    @editThangTreema?.destroy()
    super()

class ComponentConfigNode extends TreemaObjectNode
  nodeDescription: 'Component Property'
