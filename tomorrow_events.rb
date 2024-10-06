#!/usr/bin/ruby
require 'bundler/setup'
require 'calendav'
require 'icalendar'
require 'yaml'
require 'json'
require 'date'

tomorrow = (Date.today + 1).to_time
next_day = (Date.today + 2).to_time
endcheck_m1 = (Date.today + 3).to_time - 1

CONFIG = YAML.load File.read ARGV[0]

calial = Calendav::Credentials::Standard.new(
  host: CONFIG["host"],
  username: CONFIG["username"],
  password: CONFIG["password"],
  authentication: :basic_auth
)

client = Calendav.client(calial)

cals = client.calendars.list
cal_urls = cals.map {|i| i.url }.reject {|i| CONFIG["exclude"]&.include?(i) }

ev = []
eev = {}

cal_urls.each do |i|
  list = client.events.list(
    i,
    from: tomorrow,
    to: next_day - 1
  )
  elist = client.events.list(
    i,
    from: next_day,
    to: endcheck_m1
  )
  elist.each do |i|
    eev[i.url] = i.calendar_data
  end

  ev += list
end

evj = []

ev.sort_by {|i| i.dtstart }.each do |i|
  data = {}
  data["summary"] = i.summary
  if Icalendar::Values::Date === i.dtstart
    unless eev[i.url]
      # Event list includes last of all day event.
      # For example, 10 oct all event is shown in 10 oct to 11 oct (-1) and also 11 oct to 12 oct (-1.)
      # Exclude it when it is now shown in 12 oct to 13 oct (-1.)
      next
    end
  else
    data["start"] = i.dtstart.to_time.strftime("%H:%M:%S")
  end
  evj.push data
end

JSON.dump(evj, STDOUT)