#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'digest/sha1'

require '../../lib/moka'

#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite:../xfce/example.db')
DataMapper.finalize

Moka::Models::Configuration.load do |conf|
  conf.set :archive_dir, '/home/nick/websites/archive.xfce.org/'
end

generator = Moka::CGit.new
generator.run('/tmp/cgitrepos', '/var/git')
