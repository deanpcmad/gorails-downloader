#!/usr/bin/ruby
require "rss"

EMAIL    = ""
PASSWORD = ""

puts "GoRails Downloader"

def parameterize(title)
  title.downcase
    .gsub(/(\s+|\.)/, '_')
    .gsub('&', 'and')
    .gsub('/', '-')
    .gsub("(","[")
    .gsub(")","]")
    .delete("'")
end

def video_title(video)
  "#{video[:episode]}-#{parameterize(video[:title])}.mp4"
end

def video_id(str)
  str.split('-').first
end

rss_string = URI.open("https://gorails.com/episodes/pro.rss", http_basic_authentication: [EMAIL, PASSWORD]).read

rss = RSS::Parser.parse(rss_string, false)

video_urls = rss.items.map do |it|
  {
    title: it.title,
    url: it.enclosure.url,
    episode: /[0-9]{1,5}-/.match(it.enclosure.url)[0].delete("-"),
    size: it.enclosure.length / (1024 * 1024)
  }
end

puts "Found #{video_urls.size} videos on GoRails"

video_filenames = video_urls.map { |video| video_title(video) }
existing_filenames = Dir.glob("**{,/*/**}/*.mp4").map { |file| file.gsub(/videos\//, '') }.uniq
missing_filenames = video_filenames - existing_filenames
puts "Downloading #{missing_filenames.size} missing videos"

missing_video_urls = video_urls.select do |video|
  title = video_id(video_title(video))
  missing_filenames.any? { |filename| title == video_id(filename) }
end

missing_video_urls.reverse.each do |video|
  ep = video[:episode]
  filename = File.join("videos", video_title(video))
  puts filename
  puts "(#{ep}/#{video_urls.first[:episode]}) Downloading '#{video[:title]}' (#{video[:size]}mb)"
  `curl --progress-bar #{video[:url]} -o #{filename}.tmp; mv #{filename}.tmp #{filename}`
end

puts "Finished downloading #{missing_video_urls.size} videos"
