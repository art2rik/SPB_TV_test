class RequestCounter
  attr_accessor :requests

  def initialize(reset_time)
    @requests = 0
    @reset_thread = Thread.new {
      loop {
        sleep reset_time
        @requests = 0
      }
    }.run
  end

  def plus
    @requests += 1
  end
end