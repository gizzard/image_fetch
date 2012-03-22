#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require 'json'
require 'httparty'
require 'progressbar'
require 'open-uri'

class Image_fetch
	def initialize
		@service
		@username
		@path
		@pbar
		@yfrog_key = "09ACDLMP1271fcbfe5fe5480434a864440f83a17"
	end
	
	def start
		if ARGV.count == 2
			@service = ARGV[0]
			@username = ARGV[1]		
		elsif ARGV.count == 4 && ARGV[2] == 'to'
			@service = ARGV[0]
			@username = ARGV[1]
			@path = ARGV[3]
		else
			puts "usage: #{$0} service username [to PATH]"
			exit
		end
		choose_service
	end
	
protected
	def choose_service
		case @service
		when "twitpic"
			download_from_twitpic
		when "yfrog"
			download_from_yfrog
		else
			puts "#{@service} isn't available as an service\n\n"
			puts "Services:"
			puts "---------"
			puts "twitpic"
			puts "yfrog"
		end
	end
	
	def download_from_twitpic
		puts "Trying to download images for #{@username} from #{@service}\n\n"
		begin
			response = JSON.parse HTTParty.get("http://api.twitpic.com/2/users/show.json?username=#{@username}").response.body
		rescue Exception => e  
				puts e.message
				exit
		end
		unless response.nil?
			unless response['errors'].nil?
				response['errors'].each do |e|
					puts e['message']
				end
				exit
			end
			pbar = ProgressBar.new('TwitPic', response['images'].count)
			response['images'].each do |r|
				pbar.inc
				filename = "#{r['short_id']}.#{r['type']}"
				save_file("http://twitpic.com/show/full/#{r['short_id']}", filename)
			end
			pbar.finish
		end
	end
end

def download_from_yfrog
	puts "Trying to download images for #{@username} from #{@service}\n\n"
	begin
		response = JSON.parse HTTParty.get("http://yfrog.com/api/userphotos.json?screen_name=#{@username}&devkey=#{@yfrog_key}").response.body
	rescue Exception => e  
			puts e.message
			exit
	end
	unless response.nil?
		unless response['errors'].nil?
			response['errors'].each do |e|
				puts e['message']
			end
			exit
		end
		if response['result']['photos'].count > 0
			pbar = ProgressBar.new('yFrog', response['result']['photos'].count)
			response['result']['photos'].each do |r|
				begin
					pbar.inc
					photo = JSON.parse HTTParty.get("http://www.yfrog.com/api/oembed?url=http:\/\/yfrog.com/#{r['photo_link']}").response.body
					filename = File.basename(photo['url'])
					save_file(photo['url'], filename)
				rescue Exception => e
					puts e.message
				end
			end
			pbar.finish
		end
	end
end

def save_file(url, filename)
	begin
		Dir.mkdir(@path) unless File.directory?(@path)
		open(File.join(@path ||= ".", filename), 'wb') do |file|
			file << open(url).read
		end
	rescue Exception => e  
			puts "Error: #{e.message} for #{filename}"
	end
end

image_fetch = Image_fetch.new
image_fetch.start