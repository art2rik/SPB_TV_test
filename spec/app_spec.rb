require File.expand_path '../spec_helper.rb', __FILE__
require 'ruby_http_client'

describe "SpbTV" do
  URL = 'http://localhost:4567'
  let (:client) {SendGrid::Client.new(host: URL)}

  context "Put users" do
    it "Should put user and video" do
      response = client.video.register.get(query_params: {customer_id: 1, video_id: 1})
      expect(response.status_code).to eq("200")
    end

    it "Shouldn't put user and video" do
      response = client.video.register.get(query_params: {customer_id: -1, video_id: 1})
      expect(response.status_code).to eq("400")
    end
  end

  context "Get users by video id" do
    it "Should return all users by video id" do
      client.video.register.get(query_params: {customer_id: 1, video_id: 1})
      client.video.register.get(query_params: {customer_id: 2, video_id: 1})
      client.video.register.get(query_params: {customer_id: 3, video_id: 1})

      response = client.video.stream_users.get(query_params: {video_id: 1})
      result = JSON.parse response.body
      expect(result['users']).to eq(%w[1 2 3])
    end

    it "Should return bad status" do
      response = client.video.stream_users.get(query_params: {video_id: "hallow"})
      expect(response.status_code).to eq("400")
    end

    it "Should returns empty user array" do
      sleep 6

      response = client.video.stream_users.get(query_params: {video_id: 1})
      result = JSON.parse response.body
      expect(result['users']).to be_empty
    end

    it "should return users considering timing" do
      client.video.register.get(query_params: {customer_id: 1, video_id: 1})

      sleep 3

      client.video.register.get(query_params: {customer_id: 2, video_id: 1})
      client.video.register.get(query_params: {customer_id: 3, video_id: 1})

      sleep 3

      response = client.video.stream_users.get(query_params: {video_id: 1})
      result = JSON.parse response.body
      expect(result['users']).to eq(%w[2 3])
    end
  end

  context "Get user active streams" do
    it "Should return zero" do
      response = client.video.user_streams.get(query_params: {customer_id: 1})
      result = JSON.parse response.body
      expect(result['streams_count']).to be 0
    end

    it "Should return bad status" do
      response = client.video.user_streams.get(query_params: {customer_id: "wronggggid"})
      expect(response.status_code).to eq("400")
    end

    it "Should return 3 threads" do
      client.video.register.get(query_params: {customer_id: 1, video_id: 1})
      client.video.register.get(query_params: {customer_id: 1, video_id: 2})
      client.video.register.get(query_params: {customer_id: 1, video_id: 3})

      response = client.video.user_streams.get(query_params: {customer_id: 1})
      result = JSON.parse response.body
      expect(result['streams_count']).to be 3
    end

    it "Should return 3 threads considering timer" do
      client.video.register.get(query_params: {customer_id: 1, video_id: 1})

      sleep 3

      client.video.register.get(query_params: {customer_id: 1, video_id: 2})
      client.video.register.get(query_params: {customer_id: 1, video_id: 3})
      client.video.register.get(query_params: {customer_id: 1, video_id: 4})

      sleep 3

      response = client.video.user_streams.get(query_params: {customer_id: 1})
      result = JSON.parse response.body
      expect(result['streams_count']).to be 3
    end
  end
end