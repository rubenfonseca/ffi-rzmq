
require File.join(File.dirname(__FILE__), %w[spec_helper])

module ZMQ


  describe Socket do
    include APIHelper

    before(:all) do
      @ctx = Context.new
      poller_setup
    end

    after(:all) do
      @ctx.terminate
    end


    shared_examples_for "any socket" do

      it "returns -1 when there are no messages to read" do
        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        Util.resultcode_ok?(rc).should be_false
      end

      it "gets EAGAIN when there are no messages to read" do
        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        ZMQ::Util.errno.should == ZMQ::EAGAIN
      end

      it "returns the given array unmodified when there are no messages to read" do
        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        array.size.should be_zero
      end

    end

    shared_examples_for "sockets without exposed envelopes" do

      it "read the single message and returns a successful result code" do
        poller_register_socket(@receiver)

        rc = @sender.send_string('test')
        Util.resultcode_ok?(rc).should be_true
        poll_delivery
        poller_deregister_socket(@receiver)

        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        Util.resultcode_ok?(rc).should be_true
        array.size.should == 1
      end

      it "read all message parts transmitted and returns a successful result code" do
        poll_it_for_read(@receiver) do
          strings = Array.new(10, 'test')
          rc = @sender.send_strings(strings)
          Util.resultcode_ok?(rc).should be_true
        end

        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        Util.resultcode_ok?(rc).should be_true
        array.size.should == 10
      end

    end

    shared_examples_for "sockets with exposed envelopes" do

      it "read the single message and returns a successful result code" do
        poll_it_for_read(@receiver) do
          rc = @sender.send_string('test')
          Util.resultcode_ok?(rc).should be_true
        end

        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        Util.resultcode_ok?(rc).should be_true
        array.size.should == 1 + 1 # extra 1 for envelope
      end

      it "read all message parts transmitted and returns a successful result code" do
        poll_it_for_read(@receiver) do
          strings = Array.new(10, 'test')
          rc = @sender.send_strings(strings)
          Util.resultcode_ok?(rc).should be_true
        end

        array = []
        rc = @receiver.recvmsgs(array, ZMQ::NonBlocking)
        Util.resultcode_ok?(rc).should be_true
        array.size.should == 10 + 1 # add 1 for the envelope
      end

    end

    context "PUB" do

      describe "non-blocking #recvmsgs where sender connects & receiver binds" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::SUB
          assert_ok(@receiver.setsockopt(ZMQ::SUBSCRIBE, ''))
          @sender = @ctx.socket ZMQ::PUB
          @receiver.bind(endpoint)
          connect_to_inproc(@sender, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets without exposed envelopes" # see Jira LIBZMQ-270; fails with tcp transport

      end # describe 'non-blocking recvmsgs'

      describe "non-blocking #recvmsgs where sender binds & receiver connects" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::SUB
          port = connect_to_random_tcp_port(@receiver)
          assert_ok(@receiver.setsockopt(ZMQ::SUBSCRIBE, ''))
          @sender = @ctx.socket ZMQ::PUB
          @sender.bind(endpoint)
          connect_to_inproc(@receiver, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets without exposed envelopes" # see Jira LIBZMQ-270; fails with tcp transport

      end # describe 'non-blocking recvmsgs'

    end # Pub

    context "REQ" do

      describe "non-blocking #recvmsgs where sender connects & receiver binds" do
        include APIHelper

        before(:each) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::REP
          @sender = @ctx.socket ZMQ::REQ
          @receiver.bind(endpoint)
          connect_to_inproc(@sender, endpoint)
        end

        after(:each) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets without exposed envelopes"

      end # describe 'non-blocking recvmsgs'

      describe "non-blocking #recvmsgs where sender binds & receiver connects" do
        include APIHelper

        before(:each) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::REP
          @sender = @ctx.socket ZMQ::REQ
          @sender.bind(endpoint)
          connect_to_inproc(@receiver, endpoint)
        end

        after(:each) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets without exposed envelopes"

      end # describe 'non-blocking recvmsgs'

    end # REQ


    context "PUSH" do

      describe "non-blocking #recvmsgs where sender connects & receiver binds" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::PULL
          @sender = @ctx.socket ZMQ::PUSH
          @receiver.bind(endpoint)
          connect_to_inproc(@sender, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets without exposed envelopes"

      end # describe 'non-blocking recvmsgs'

      describe "non-blocking #recvmsgs where sender binds & receiver connects" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::PULL
          @sender = @ctx.socket ZMQ::PUSH
          @sender.bind(endpoint)
          connect_to_inproc(@receiver, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets without exposed envelopes"

      end # describe 'non-blocking recvmsgs'

    end # PUSH


    context "DEALER" do

      describe "non-blocking #recvmsgs where sender connects & receiver binds" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::ROUTER
          @sender = @ctx.socket ZMQ::DEALER
          @receiver.bind(endpoint)
          connect_to_inproc(@sender, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets with exposed envelopes"

      end # describe 'non-blocking recvmsgs'

      describe "non-blocking #recvmsgs where sender binds & receiver connects" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::ROUTER
          @sender = @ctx.socket ZMQ::DEALER
          @sender.bind(endpoint)
          connect_to_inproc(@receiver, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets with exposed envelopes"

      end # describe 'non-blocking recvmsgs'

    end # DEALER


    context "XREQ" do

      describe "non-blocking #recvmsgs where sender connects & receiver binds" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::XREP
          @sender = @ctx.socket ZMQ::XREQ
          @receiver.bind(endpoint)
          connect_to_inproc(@sender, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets with exposed envelopes"

      end # describe 'non-blocking recvmsgs'

      describe "non-blocking #recvmsgs where sender binds & receiver connects" do
        include APIHelper

        before(:all) do
          endpoint = "inproc://nonblocking_test"
          @receiver = @ctx.socket ZMQ::XREP
          @sender = @ctx.socket ZMQ::XREQ
          @sender.bind(endpoint)
          connect_to_inproc(@receiver, endpoint)
        end

        after(:all) do
          @receiver.close
          @sender.close
        end

        it_behaves_like "any socket"
        it_behaves_like "sockets with exposed envelopes"

      end # describe 'non-blocking recvmsgs'

    end # XREQ

  end # describe Socket


end # module ZMQ
