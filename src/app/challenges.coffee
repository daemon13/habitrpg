_ = require 'lodash'
helpers = require 'habitrpg-shared/script/helpers'

module.exports.app = (appExports, model) ->
  browser = require './browser'
  user = model.at '_user'

  appExports.challengeCreate = (e,el) ->
    [type, gid] = [$(el).attr('data-type'), $(el).attr('data-gid')]
    model.set '_challenge.new',
      name: ''
      habits: []
      dailys: []
      todos: []
      rewards: []
      id: model.id()
      uid: user.get('id')
      user: helpers.username(model.get('_user.auth'), model.get('_user.profile.name'))
      group: {type, id:gid}
      timestamp: +new Date

  appExports.challengeSave = ->
    gid = model.get('_challenge.new.group.id')
    debugger
    model.unshift "groups.#{gid}.challenges", model.get('_challenge.new'), ->
      browser.growlNotification('Challenge Created','success')
      challengeDiscard()

  appExports.challengeDiscard = challengeDiscard = -> model.del '_challenge.new'

  appExports.challengeSubscribe = (e) ->
    chal = e.get()

    # Add challenge name as a tag for user
    tags = user.get('tags')
    unless tags and _.find(tags,{id: chal.id})
      model.push '_user.tags', {id: chal.id, name: chal.name, challenge: true}

    tags = {}; tags[chal.id] = true
    # Add all challenge's tasks to user's tasks
    userChallenges = user.get('challenges')
    user.unshift('challenges', chal.id) unless userChallenges and (userChallenges.indexOf(chal.id) != -1)
    _.each ['habit', 'daily', 'todo', 'reward'], (type) ->
      _.each chal["#{type}s"], (task) ->
        task.tags = tags
        task.challenge = chal.id
        task.group = {id: chal.group.id, type: chal.group.type}
        model.push("_#{type}List", task)
        true

  appExports.challengeUnsubscribe = (e) ->
    chal = e.get()
    i = user.get('challenges')?.indexOf chal.id
    user.remove("challenges.#{i}") if i? and i != -1
    _.each ['habit', 'daily', 'todo', 'reward'], (type) ->
      _.each chal["#{type}s"], (task) ->
        model.remove "_#{type}List", _.findIndex(model.get("_#{type}List",{id:task.id}))
        model.del "_user.tasks.#{task.id}"
        true

  appExports.challengeCollapse = (e, el) ->
    $(el).next().toggle()
    i = $(el).find('i').toggleClass('icon-chevron-right icon-chevron-down')