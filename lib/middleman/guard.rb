require "guard"
require "guard/guard"
require "guard/livereload"

module Middleman::Guard
  def self.start(options={}, livereload={})
    options_hash = ""
    options.each do |k,v|
      options_hash << ", :#{k} => '#{v}'"
    end
    
    guardfile_contents = %Q{
      guard 'middleman'#{options_hash} do 
        watch("config.rb")
      end
    }
    
    if livereload
      livereload_options_hash = ""
      livereload.each do |k,v|
        livereload_options_hash << ", :#{k} => '#{v}'"
      end
      
      guardfile_contents << %Q{
        guard 'livereload'#{livereload_options_hash} do 
          watch(%r{^source/^[^\.](.*)$})
        end
      }
    end
    
    ::Guard.start({ :guardfile_contents => guardfile_contents })
  end
end

module Guard
  class Middleman < Guard
    def initialize(watchers = [], options = {})
      super
      @options = {
        :port => '4567'
      }.update(options)
    end
    
    def start
      server_start
    end
  
    def run_on_change(paths)
      server_stop
      server_start
    end

  private
    def server_start
      puts "== The Middleman is standing watch on port #{@options[:port]}"
      @server_options = { :Port => @options[:port], :AccessLog => [] }
      @server_job = fork do
        @server_options[:app] = ::Middleman.server.new
        ::Rack::Server.new(@server_options).start
      end
    end
  
    def server_stop
      puts "== The Middleman is shutting down"
      Process.kill("KILL", @server_job)
      Process.wait @server_job
      @server_job = nil
      @server_options[:app] = nil
    end
  end
end