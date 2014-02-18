require 'net/http'

class ImportController < ApplicationController

	before_filter :authenticate_user!

	# instructions and prompts the user for a URL
	def step1
	end

	# verifies identify and gets a script list
	def step2
		url = params[:url]
		userscripts_id = get_userscripts_id(url)
		if userscripts_id.nil?
			render :text => 'Invalid userscripts.org profile URL.', :layout => true
			return
		end
		case check_for_url_on_userscripts("http://userscripts.org/users/#{userscripts_id}")
			when :failure
				render :text => 'userscripts.org profile check failed.', :layout => true
				return
			when :nourl
				render :text => 'Greasy Fork URL not found on userscripts.org profile.', :layout => true
				return
			when :wronguser
				render :text => 'Greasy Fork URL found on userscripts.org profile, but it wasn\'t yours.', :layout => true
				return
		end
		@new_scripts = get_script_list(userscripts_id)
		if @new_scripts.empty?
			render :text => 'No scripts found on userscripts.org.', :layout => true
			return
		end
		# check for updates
		@updated_scripts = {}
		Script.where(['userscripts_id in (?)', @new_scripts.keys]).each do |script|
			if @new_scripts.has_key?(script.userscripts_id)
				@updated_scripts[script.userscripts_id] = @new_scripts.delete(script.userscripts_id)
			end
		end
		# save the ids, we will make sure in the next step that they pick one of these
		user_session[:imported_scripts] = @new_scripts.merge(@updated_scripts).keys
	end

	# validate, then add or update the chosen scripts
	def step3
		@results = {:new => [], :updated => [], :unchanged => [], :failed => [], :needsdescription => {}}
		user_session[:imported_scripts].select{|id|params[:userscripts_ids].include?(id.to_s)}.each do |id|
			name = params["imported-name-#{id}"]
			code = download("http://userscripts.org/scripts/source/#{id}.user.js")
			if code.nil?
				@results[:failed] << "#{name} - Could not download source."
				next
			end
			code.force_encoding(Encoding::UTF_8)
			sv = ScriptVersion.new
			sv.code = code
			# step 3 lets us resubmit with a description for those that are missing
			if !params["needsdescription-#{id}"].nil? and !params["needsdescription-#{id}"].empty?
				sv.code = sv.inject_meta(:description => params["needsdescription-#{id}"])
			end
			sv.version = "1.#{Time.now.utc.strftime('%Y%m%d%H%M%S')}"
			sv.rewritten_code = sv.calculate_rewritten_code
			script = Script.where(['userscripts_id = ?', id]).first
			script_is_new = script.nil?
			if script_is_new
				script = Script.new
				script.user = current_user
			else
				sv.changelog = 'Imported from userscripts.org'
				puts script.script_versions.last.code
				#raise Diffy::Diff.new(script.script_versions.last.code, sv.code).to_s if script.id == 24
				if sv.code == script.script_versions.last.code
					@results[:unchanged] << name
					next
				end
			end
			script.apply_from_script_version(sv)
			script.userscripts_id = id
			if script.description.nil? or script.description.empty?
				@results[:needsdescription][id] = name
				next
			end
			if !script.valid? | !sv.valid?
				# prefer script_version error messages, but show script error messages if necessary
				@results[:failed] << "#{name} - #{(sv.errors.full_messages.empty? ? script.errors.full_messages : sv.errors.full_messages).join('. ')}."
				next
			end
			script.script_versions << sv
			sv.script = script
			script.save!
			sv.save!
			if script_is_new
				@results[:new] << name
			else
				@results[:updated] << name
			end
		end
		# need to keep this for resubmit on step 3 if necessary
		user_session.delete(:imported_scripts) if @results[:needsdescription].empty?
	end

private

	def get_userscripts_id(url)
		profile_url_match = /^http:\/\/userscripts.org\/users\/([0-9]+)(\/.*)?$/.match(url)
		return nil if profile_url_match.nil?
		return profile_url_match[1]
	end
	
	def download(url)
		url = URI.parse(url)
		req = Net::HTTP::Get.new(url.request_uri)
		res = Net::HTTP.start(url.host, url.port) {|http|
		  http.request(req)
		}
		return nil if res.code != '200'
		return res.body
	end

	def check_for_url_on_userscripts(url)
		return :success
		content = download(url)
		return :failure if content.nil?
		our_url_match = /https?:\/\/greasyfork.org\/users\/([0-9]+)/.match(content)
		#our_url_match = /https?:\/\/example.com\/users\/([0-9]+)/.match(content)
		return :nourl if our_url_match.nil?
		return current_user.id == our_url_match[1].to_i ? :success : :wronguser
	end

	def get_script_list(userscripts_id)
		scripts = {}
		i = 1
		# loop through each page of results - 20 is a reasonable limit as the most profilic
		# author on userscripts has < 1000
		while i < 20
			content = download("http://userscripts.org/users/#{userscripts_id}/scripts?page=#{i}")
			page_scripts = content.scan(/<a href="\/scripts\/show\/([0-9]+)[^>]+>([^<]+)/)
			return scripts if page_scripts.empty?
			page_scripts.each do |match|
				scripts[match[0].to_i] = match[1]
			end
			i = i + 1
		end
		return scripts
	end
end
