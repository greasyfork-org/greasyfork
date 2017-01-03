module UsersHelper

	def user_list_link(label, sort = nil)
		is_link = false
		if (sort.nil? && !params[:sort].blank?) || (sort.present? && sort != params[:sort])
			is_link = true
			opts = {sort: sort}
			opts[:q] = params[:q] if params[:q].present?
			label = link_to label, users_path(opts)
		end
		return ("<li class=\"list-option#{is_link ? '' : ' list-current'}\">" + label + '</li>').html_safe
	end

end
