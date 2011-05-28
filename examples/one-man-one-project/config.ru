#!/usr/bin/env ruby

require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'digest/sha1'

require '../../lib/moka'

# Connect to the database
directory = File.expand_path(File.dirname(__FILE__))
db = File.join(directory, 'example.db')

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite://' + db)

# From http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
def wrap_text(txt, col = 72)
  txt.gsub(/(.{1,#{col}})( +|$)\n?|(.{#{col}})/, "\\1\\3\n")
end

# Identica configuration
use Moka::Middleware::Identica do |identica|
  identica.username = 'username'
  identica.password = 'password'
  identica.group    = 'group'
end

# Feed configuration and template handling
use Moka::Middleware::Feeds do |feeds|
  feeds.base_url = 'http://archive.xfce.org/feeds/'

  feeds.project_feed_url do |project|
    URI.join(feeds.base_url, 'project/', project.name).to_s
  end

  feeds.project_feed_filename do |project|
    "/home/nick/websites/archive.xfce.org/feeds/project/#{project.name}"
  end

  feeds.collection_feed_url do |collection|
    URI.join(feeds.base_url, 'collection/', collection.name).to_s
  end

  feeds.collection_feed_filename do |collection|
    "/home/nick/websites/archive.xfce.org/feeds/collection/#{collection.name}"
  end

  feeds.project_body do |release, message, sender|
    ERB.new(File.read('templates/project_feed_entry.erb')).result(binding)
  end

  feeds.collection_body do |release, message, sender|
    ERB.new(File.read('templates/collection_feed_entry.erb')).result(binding)
  end
end

# Mailinglist configuration and template handling
use Moka::Middleware::Mailinglists do |mailer|
  mailer.lists = ['xfce-announce@xfce.org', 'xfce@xfce.org', 'thunar-dev@xfce.org', 'nickschermer@gmail.com']
  
  mailer.project_subject do |release, message, sender|
    "ANNOUNCE: #{release.project.name} #{release.version} released"
  end

  mailer.project_body do |release, message, sender| 
    ERB.new(File.read('templates/project_release_mail.erb')).result(binding)
  end
  
  mailer.collection_subject do |release, message, sender|
    "ANNOUNCE: #{release.collection.display_name} #{release.version} released"
  end

  mailer.collection_body do |release, message, sender|
    ERB.new(File.read('templates/collection_release_mail.erb')).result(binding)
  end
end

# global configuration
Moka::Models::Configuration.load do |conf|
  conf.set :moka_url, 'https://releases.xfce.org'
  conf.set :archive_dir, '/home/nick/websites/archive.xfce.org/'
  conf.set :mirror, 'http://archive.xfce.org/'
  conf.set :collection_release_pattern, /^([0-9]).([0-9]+)(pre[0-9])?$/
end

# Uncheck for production environment
DataMapper.auto_upgrade!
DataMapper.finalize

# create dummy roles
admin = Moka::Models::Role.first_or_create(:name => 'admin')
admin.save

goodies = Moka::Models::Role.first_or_create(:name => 'goodies')
goodies.save

# create dummy user
nick = Moka::Models::Maintainer.first_or_create(
  { :username => 'nick' },
  { :realname => 'Nick Schermer',
    :password => Digest::SHA1.hexdigest('test'),
    :email => 'nick@xfce.org' }
)
nick.roles << admin
nick.roles << goodies
nick.save

jannis = Moka::Models::Maintainer.first_or_create(
  { :username => 'jannis' },
  { :realname => 'Jannis Pohlmann',
    :password => Digest::SHA1.hexdigest('test'),
    :email => 'jannis@xfce.org' }
)
jannis.roles << goodies
jannis.save

jeromeg = Moka::Models::Maintainer.first_or_create(
  { :username => 'jeromeg' },
  { :realname => 'Jérôme Guelfucci',
    :password => Digest::SHA1.hexdigest('test'),
    :email => 'jeromeg@xfce.org' }
)
jeromeg.roles << goodies
jeromeg.save

panel = Moka::Models::Project.first_or_create(
  { :name =>           'xfce4-panel' },
  { :website =>        'http://www.xfce.org',
    :description =>    'Xfce\'s Panel' }
)
panel.maintainers << nick
panel.save

thunar = Moka::Models::Project.first_or_create(
  { :name =>           'thunar' },
  { :website =>        'http://thunar.xfce.org',
    :description =>    'Xfce\'s File Manager' }
)
thunar.maintainers << nick
thunar.maintainers << jannis
thunar.save

# create dummy classification
collection = Moka::Models::Collection.first_or_create(
  { :name => 'xfce' },
  { :display_name => 'Xfce',
    :website => 'http://www.xfce.org' }
)
collection.maintainers << nick
collection.maintainers << jannis
collection.maintainers << jeromeg
collection.save

run Moka::Application
