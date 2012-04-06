require "test_helper"
require "print_queue"

describe PrintQueue do
  subject do
    PrintQueue.new(123)
  end

  describe "#add_print_data" do
    it "puts the base64-encoded data into a redis list for that printer" do
      Resque.redis.expects(:lpush).with("printer/123/queue", Base64.encode64("data"))
      subject.add_print_data("data")
    end
  end

  describe "#data_waiting?" do
    it "returns true if data exists" do
      Resque.redis.stubs(:llen).with("printer/123/queue").returns(1)
      subject.data_waiting?.must_equal true
    end

    it "returns false if data doesn't exist" do
      Resque.redis.stubs(:llen).with("printer/123/queue").returns(0)
      subject.data_waiting?.must_equal false
    end
  end

  describe "#archive_and_return_print_data" do
    describe "when no data exists" do
      before do
        Resque.redis.stubs(:lpop).with("printer/123/queue").returns(nil)
      end

      it "returns nil if no print data exists" do
        subject.archive_and_return_print_data.must_equal nil
      end

      it "doesn't put anything into the archive if no print data exists" do
        Resque.redis.expects(:lpush).with("printer/123/archive", anything).never
        subject.archive_and_return_print_data
      end
    end

    describe "when data exists" do
      before do
        Resque.redis.stubs(:lpop).with("printer/123/queue").returns(Base64.encode64("data"))
      end

      it "returns the base64-decoded data if some exists" do
        subject.archive_and_return_print_data.must_equal "data"
      end

      it "adds the data to the archive list if some is popped" do
        Resque.redis.expects(:lpush).with("printer/123/archive", Base64.encode64("data"))
        subject.archive_and_return_print_data
      end
    end
  end
end