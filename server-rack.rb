#!/usr/bin/env ruby
# Usage:
#
# $ ruby rack-server.rb
require 'rack'
require 'json'
require 'digest'

module Hasher
  def self.generate_id(object_data)
    Digest::SHA2.hexdigest(object_data)
  end
end

class Repository
  def initialize(data)
    @data = data
    @semaphore = Mutex.new
  end

  def store(id, object_data)
    @semaphore.synchronize do
      return unless fetch_without_lock(id).nil?

      @data[id] = object_data
      {
        size: object_data.length,
        oid: id
      }
    end
  end

  def fetch(id)
    @semaphore.synchronize do
      fetch_without_lock(id)
    end
  end

  def delete(id)
    @semaphore.synchronize do
      @data.delete(id)
    end
  end

  private

  def fetch_without_lock(id)
    @data.fetch(id, nil)
  end
end
class Storage
  def initialize
    @repositories = {}
    @semaphore = Mutex.new
  end

  def repository(repository_name, create: false)
    @semaphore.synchronize do
      data = @repositories[repository_name]
      if create && data.nil?
        @repositories[repository_name] = {}
        data = @repositories[repository_name]
      end
      Repository.new(data) unless data.nil?
    end
  end
end

class DataStorageServer
  # You may initialize any variables you want to use across requests here
  def initialize
    @storage = Storage.new
  end

  # Download an Object
  #
  # GET /data/{repository}/{objectID}
  # Response
  #
  # Status: 200 OK
  # {object data}
  # Objects that are not on the server will return a 404 Not Found.
  def get(path)
    repo_name, id = parse_path(path)
    repo = @storage.repository(repo_name)

    return ['404', {}, ['not found']] if repo.nil?

    object = repo.fetch(id)

    if object
      ['200', {}, [object]]
    else
      ['404', {}, ['not found']]
    end
  end

  def put(path, body)
    repo_name = parse_path(path).first
    repo = @storage.repository(repo_name, create: true)
    id = Hasher.generate_id(body)
    response = repo.store(id, body)

    return ['409', {}, ['already exists']] if response.nil?

    ['201', { 'content-type' => 'application/json' }, [JSON.dump(response)]]
  end

  def delete(path)
    repo_name, id = parse_path(path)
    repo = @storage.repository(repo_name, create: false)

    return ['404', {}, ['not found']] if repo.nil?

    success = repo.delete(id)

    if success
      ['200', {}, []]
    else
      ['404', {}, ['not found']]
    end
  end

  def call(env)
    path = env['PATH_INFO']
    case env['REQUEST_METHOD']
    when 'GET'
      get(path)
    when 'PUT'
      body = env['rack.input'].read
      put(path, body)
    when 'DELETE'
      delete(path)
    end
  end

  private

  def parse_path(path)
    return [] unless path.start_with?('/data/')

    path.gsub('/data/', '').split('/').compact
  end
end

# This starts the server if the script is invoked from the command line. No
# modifications needed here.
if __FILE__ == $0
  app = Rack::Builder.new do
    use Rack::Reloader
    run DataStorageServer.new
  end.to_app

  Rack::Server.start(app: app, Port: 8282)
end