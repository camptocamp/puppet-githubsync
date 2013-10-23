#!/usr/bin/ruby1.9.1
#
# Pipe content into this script
# It will post it to a private gist
# with a file named ${fqdn}.json

require 'octokit'
require 'facter'

gist_id = ARGV[0]

client = Octokit::Client.new(:netrc => true)

fqdn = Facter.value(:fqdn)
file = "#{fqdn}.json"

client.edit_gist(gist_id, {
  :files => {
    file => {"content" => STDIN.read},
  }
})

