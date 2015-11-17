require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::SystemResources" do
  before :each do
    Eye::SystemResources.cache.clear
  end

  it "should get memory" do
    x = Eye::SystemResources.memory($$)
    x.should > 20.megabytes
    x.should < 300.megabytes
  end

  it "should get cpu" do
    x = Eye::SystemResources.cpu($$)
    x.should >= 0
    x.should <= 100
  end

  it "should get cputime" do
    x = Eye::SystemResources.cputime($$)
    x.should >= 0
    x.should <= 30 * 60
  end

  it "when unknown pid" do
    pid = 12342341
    Eye::SystemResources.cpu(pid).should == nil
    Eye::SystemResources.memory(pid).should == nil
    Eye::SystemResources.children(pid).should == []

    pid = nil
    Eye::SystemResources.cpu(pid).should == nil
    Eye::SystemResources.memory(pid).should == nil
    Eye::SystemResources.start_time(pid).should == nil
    Eye::SystemResources.children(pid).should == []
  end

  it "should get start time" do
    x = Eye::SystemResources.start_time($$)
    x.should >= 1000000000
    x.should <= 2000000000
  end

  it "should get children" do
    @pid = fork { at_exit{}; sleep 3; exit }
    Process.detach(@pid)
    sleep 0.5
    x = Eye::SystemResources.children($$)
    x.class.should == Array
    x.should include(@pid)
  end

  describe "leaf_child" do
    it "should get leaf_child" do
      @pid = fork { at_exit{}; sleep 3; exit }
      Process.detach(@pid)
      sleep 0.5
      x = Eye::SystemResources.leaf_child($$)
      x.should == @pid
    end

    it "complex leaf_child" do
      pid = Process.spawn(*Shellwords.shellwords('sh -c "sleep 10 | logger"'))
      x = Eye::SystemResources.leaf_child($$)
      args = Eye::SystemResources.args(x)
      args.should_not include('sh')
      args.should_not include('logger')
      args.should start_with('sleep')
    end

    it "super complex leaf_child" do
      str = "/bin/sh #{C.sample_dir}/leaf_child.sh | logger"
      pid = Process.spawn(*Shellwords.shellwords('sh -c "' + str + '"'))
      Process.detach(pid)
      sleep 0.5
      x = Eye::SystemResources.leaf_child($$)
      args = Eye::SystemResources.args(x)
      args.should == 'sleep 15'
    end
  end
end
