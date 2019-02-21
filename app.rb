require 'sinatra'
require 'sinatra/async'
require 'json'
require_relative 'lib/concurrent_storage.rb'
require_relative 'lib/request_counter.rb'

register Sinatra::Async

set :server, :thin
set :request_counter, RequestCounter.new(60)

helpers do
  def render_error(message)
    { status: 'bad',
      message: message }.to_json
  end

  def validates?(param)
    !param.nil? && param.to_i > 0 ? true : false
  end
end

before do
  settings.request_counter.plus
end

# Registers user and video
apost '/video/register' do
  customer_id = params[:customer_id]
  video_id    = params[:video_id]

  unless validates?(customer_id) && validates?(video_id)
    status 400
    body(render_error("Wrong params customer_id or video_id"))
    return
  end

  storage = ConcurrentStorage.instance
  storage.put(customer_id, video_id)


  status 200
  body({ customer_id: customer_id,
         video_id: video_id,
         status: 'ok' }.to_json)
end

aget '/video/user_streams' do
  customer_id = params[:customer_id]

  unless validates?(customer_id)
    status 400
    body(render_error("Wrong param customer_id"))
    return
  end

  storage = ConcurrentStorage.instance
  threads_num = storage.get(:threads_number, customer_id)

  status 200
  body({ customer_id: customer_id,
         streams_count: threads_num,
         status: 'ok' }.to_json)
end

aget '/video/stream_users' do
  video_id = params[:video_id]

  unless validates?(video_id)
    status 400
    body(render_error("Wrong param video_id"))
    return
  end

  storage = ConcurrentStorage.instance
  users = storage.get(:video_users, video_id)

  status 200
  body({ video_id: video_id,
         users: users,
         status: 'ok' }.to_json)
end

aget '/video/last_requests' do
  status 200
  body( { requests_last_min: settings.request_counter.requests,
          status: 'ok' }.to_json )
end

# Storage worker
# Cleans all inactive video threads
Thread.new {
  puts 'Worker are enabled'
  loop {
    storage = ConcurrentStorage.instance
    storage.clean
    sleep 1
  }
}.run



