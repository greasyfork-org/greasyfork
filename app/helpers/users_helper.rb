module UsersHelper

	def user_list_link(label, sort = nil)
		is_link = false
		if sort != params[:sort]
			is_link = true
			label = link_to label, users_path(:sort => sort)
		end
		return ("<li class=\"list-option#{is_link ? '' : ' list-current'}\">" + label + '</li>').html_safe
	end

end
