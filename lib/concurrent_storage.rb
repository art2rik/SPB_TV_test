class ConcurrentStorage
  TIMEOUT = 5

  def self.instance
    @@storage ||= ConcurrentStorage.new
  end

  def initialize
    @mutex = Mutex.new
    @customer_videos = {}
  end


  def get(type, *args)
    case type
    when :threads_number
      get_thread_number(args[0])
    when :video_users
      get_video_users(args[0])
    else
      raise 'wrong type'
    end
  end

  # Returns number of threads which user watches now
  def get_thread_number(customer_id)
    number = 0
    @mutex.synchronize {
      number = @customer_videos.include?(customer_id) ? @customer_videos[customer_id].count : 0
    }

    number
  end

  # Returns all users what watches some video
  def get_video_users(video_id)
    users = []
    @mutex.synchronize {
      @customer_videos.each do |customer_id, videos|
        videos.each do |v|
          users << customer_id if v[0] == video_id && !users.include?(customer_id)
        end
      end
    }

    users
  end

  # Adds user video pair to storage
  def put(*args)
    customer_id = args[0]
    video_id = args[1]

    @mutex.synchronize {
      @customer_videos[customer_id] = [] unless @customer_videos[customer_id]
      @customer_videos[customer_id].each_with_index do |video, i|
        if video[0] == video_id; @customer_videos[customer_id][i][1] = Time.now; return end
      end
      @customer_videos[customer_id] << [video_id, Time.now]
    }
  end

  def clean
    @mutex.synchronize {
      @customer_videos.each do |customer_id, videos|
        videos.each_with_index do |v, i|
          @customer_videos[customer_id].delete_at(i) if (Time.now - v[1]) >= TIMEOUT
        end
      end
    }
  end
end