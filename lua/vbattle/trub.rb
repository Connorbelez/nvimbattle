#!/usr/bin/env ruby
# Requires msgpack-rpc: gem install msgpack-rpc
#
# To run this script, execute it from a running Nvim instance (notice the
# trailing '&' which is required since Nvim won't process events while
# running a blocking command):
#
#   :!./hello.rb &
#
# Or from another shell by setting NVIM_LISTEN_ADDRESS:
$ NVIM_LISTEN_ADDRESS=[address] ./hello.rb
require 'msgpack/rpc'
require 'msgpack/rpc/transport/unix'
nvim = MessagePack::RPC::Client.new(MessagePack::RPC::UNIXTransport.new, ENV['NVIM_LISTEN_ADDRESS'])
result = nvim.call(:nvim_command, 'echo "hello world!"')
