_ = require('underscore')._
CommonUpdater = require('../main').CommonUpdater

describe 'CommonUpdater', ->
  it 'should initialize without options', ->
    updater = new CommonUpdater()
    expect(updater).toBeDefined()

  it 'should create logger', ->
    updater = new CommonUpdater( { logentries_token: '123' } )
    expect(updater.log).toBeDefined()

describe '#initProgressBar', ->
  it 'should create progress bar', ->
    updater = new CommonUpdater( { show_progress: true } )
    updater.initProgressBar 'foo', 42
    expect(updater.bar).toBeDefined()
    updater.bar.terminate()

describe '#tickProgress', ->
  it 'should update progress bar', ->
    updater = new CommonUpdater( { show_progress: true } )
    updater.initProgressBar 'bar', 2
    expect(updater.bar.curr).toBe 0
    updater.tickProgress()
    expect(updater.bar.curr).toBe 1
    updater.tickProgress()
    expect(updater.bar.curr).toBe 2
    
describe '#returnResult', ->
  it 'should terminate progress bar', (done) ->
    updater = new CommonUpdater( { show_progress: true } )
    updater.initProgressBar 'blabla', 7
    updater.returnResult true, 'some text', (ret) ->
      done()
      # if bar isn't terminate this test will hang

  it 'should handle a single message', (done) ->
    updater = new CommonUpdater()
    updater.returnResult true, 'Hello', (ret) ->
      expect(ret.status).toBe true
      expect(ret.message).toBe 'Hello'
      done()

  it 'should handle a singelton array message', (done) ->
    updater = new CommonUpdater()
    updater.returnResult false, [ 'Hi' ], (ret) ->
      expect(ret.status).toBe false
      expect(ret.message).toBe 'Hi'
      done()

  it 'should summarize multiple message', (done) ->
    updater = new CommonUpdater()
    updater.returnResult true, [ 'Hi', 'Hello', 'Servus', 'Hi', 'Servus', 'Servus' ], (ret) ->
      expect(ret.status).toBe true
      expect(_.size(ret.message)).toBe 3
      expect(ret.message['Hi']).toBe 2
      expect(ret.message['Hello']).toBe 1
      expect(ret.message['Servus']).toBe 3
      done()

  it 'should send info log to logentries', (done) ->
    updater = new CommonUpdater( { logentries_token: 'abc' } )
    spyOn(updater.log, 'log')
    updater.returnResult true, 'txt', (ret) ->
      expectedMessage =
        component: 'CommonUpdater'
        status: true
        message: 'txt'
      expect(updater.log.log).toHaveBeenCalledWith('info', expectedMessage)
      done()

  it 'should send error log to logentries', (done) ->
    updater = new CommonUpdater( { logentries_token: 'abc' } )
    spyOn(updater.log, 'log')
    updater.returnResult false, [ 'Oops' ], (ret) ->
      expectedMessage =
        component: 'CommonUpdater'
        status: false
        message: 'Oops'
      expect(updater.log.log).toHaveBeenCalledWith('err', expectedMessage)
      done()