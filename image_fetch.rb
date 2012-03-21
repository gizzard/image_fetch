# Retrieve a JSON Resource
require 'json'
require 'httparty'
require 'open-uri'

class Image_fetch
	def initialize
		@service
		@username
	end
	
	def start
		if ARGV.count != 2
			puts "usage: #{$0} service username"
			exit
		else
			@service = ARGV[0]
			@username = ARGV[1]
			puts "Trying to download images for #{@username} from #{@service}\n\n"
			choose_service
		end
	end
	
protected
	def choose_service
		case @service
		when "twitpic"
			download_from_twitpic
		else
			puts "#{@service} isn't available as an service\n\n"
			puts "Services:"
			puts "---------"
			puts "twitpic"
		end
	end
	
	def download_from_twitpic
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
			response['images'].each do |r|
				begin
					filename = "#{r['short_id']}.#{r['type']}"
					puts "Download #{filename}"
					open("#{filename}", 'wb') do |file|
						file << open("http://twitpic.com/show/full/#{r['short_id']}").read
					end
				rescue Exception => e  
						puts "Error: #{e.message} for #{filename}"
				end
			end
		end
	end
end

image_fetch = Image_fetch.new
image_fetch.start