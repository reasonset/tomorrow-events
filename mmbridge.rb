#!/usr/bin/ruby
require 'json'
require 'yaml'
require 'date'

CONFIG = YAML.load File.read ARGV[0]

script = File.join File.dirname(__FILE__), "tomorrow_events.rb"
events = nil

IO.popen(["ruby", script, ARGV[0]]) do |io|
  events = JSON.load(io)
end

tomorrow = Date.today + 1
str = [sprintf("[%s] Tomorrow Events:", tomorrow), ""]

exit 0 if events.empty?

events.each do |e|
  str << sprintf("%s (%s)", e["summary"], (e["start"] || "ALL"))
end

data = {
  "text" => str.join("\n"),
  "icon_emoji" => "alarm_clock",
  "username" => "Tomorrow Events"
}

system("curl", "-X", "POST", "-H", "Content-Type: application/json", "-d", JSON.dump(data), CONFIG["hook"])