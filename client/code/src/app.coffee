App = Ember.Application.create()

App.ApplicationController = Ember.Controller.extend()
App.ApplicationView = Ember.View.extend(templateName: "application")

App.AllContributorsController = Ember.ArrayController.extend()
App.AllContributorsView = Ember.View.extend(templateName: "contributors")

App.OneContributorView = Ember.View.extend(templateName: "a-contributor")
App.OneContributorController = Ember.ObjectController.extend()

App.DetailsView = Ember.View.extend(templateName: "contributor-details")


App.Router = Ember.Router.extend
  enableLogging: true
  root: Ember.Route.extend
    contributors: Ember.Route.extend
      route: "/"
      showContributor: Ember.Route.transitionTo('aContributor')
      connectOutlets: (router) ->
        router.get("applicationController").connectOutlet("allContributors", App.Contributor.find())
    aContributor: Ember.Route.extend
      route: "/:githubUserName"
      showAllContributors: Ember.Route.transitionTo("contributors")
      connectOutlets: (router, context) ->
        router.get("applicationController").connectOutlet("oneContributor", context)
      serialize: (router, context) ->
        githubUserName: context.get('login')
      deserialize: (router, urlParams) ->
        App.Contributor.find(urlParams.githubUserName)
      # child states
      initialState: "details"
      details: Ember.Route.extend
        route: "/"
        connectOutlets: (router) ->
          router.get('oneContributorController.content').loadMoreDetails()
          router.get("oneContributorController").connectOutlet("details")
      repos: Ember.Route.extend
        route: "/repos"
        connectOutlets: (router) ->
          router.get("oneContributorController").connectOutlet("repos")

App.initialize()

App.Contributor = Ember.Object.extend()
App.Contributor.reopenClass
  allContributors: []
  find: ->
    $.ajax
      url: "https://api.github.com/repos/emberjs/ember.js/contributors"
      dataType: "jsonp"
      context: this
      success: (response) ->
        response.data.forEach ((contributor) ->
          @allContributors.addObject App.Contributor.create(contributor)
        ), this
    @allContributors
  findOne: (username) ->
    contributor = App.Contributor.create(login: username)
    $.ajax
      url: "https://api.github.com/repos/emberjs/ember.js/contributors"
      dataType: "jsonp"
      context: contributor
      success: (response) ->
        @setProperties response.data.findProperty("login", username)
    contributor    
  loadMoreDetails: ->
    $.ajax
      url: "https://api.github.com/users/#{this.get('login')}"
      context: this
      dataType: 'jsonp'
      success: (response) ->
        this.setProperties(response.data)
