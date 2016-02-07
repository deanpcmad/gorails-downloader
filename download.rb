#!/usr/bin/ruby
require "rss"

EMAIL    = ""
PASSWORD = ""

puts "GoRails Downloader"

rss_string = open("https://gorails.com/episodes/pro.rss", http_basic_authentication: [EMAIL, PASSWORD]).read

rss = RSS::Parser.parse(rss_string, false)

videos_urls = rss.items.map { |it|
  {
    title: it.title,
    url: it.enclosure.url,
    episode: /[0-9]{1,5}-/.match(it.enclosure.url)[0].delete("-"),
    size: it.enclosure.length / (1024 * 1024)
  }
}.reverse

puts "Found #{videos_urls.size} videos on GoRails"

videos_filenames = videos_urls.map {|k| k[:url].split('/').last }
existing_filenames = Dir.glob("**{,/*/**}/*.mp4").map {|f| f.gsub("videos/", "")}
missing_filenames = videos_filenames - existing_filenames
puts "Downloading #{missing_filenames.size} missing videos"

missing_videos_urls = videos_urls.select { |video_url| missing_filenames.any? { |filename| video_url[:url].match filename } }

missing_videos_urls.each do |video_url|
  filename = File.join("videos", video_url[:url].split('/').last)
  puts "(#{video_url[:episode]}/#{videos_urls.last[:episode]}) Downloading '#{video_url[:title]}' (#{video_url[:size]}mb)"
  `curl --progress-bar #{video_url[:url]} -o #{filename}.tmp`
  `mv #{filename}.tmp #{filename}`
end

puts "Finished downloading #{missing_videos_urls.size} videos"