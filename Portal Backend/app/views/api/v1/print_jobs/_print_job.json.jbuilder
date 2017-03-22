json.extract! print_job, :id, :status, :card_template_id, :shipping_provider_id

json.organization do
	json.id print_job.organization.id
	json.name print_job.organization.name
end

json.list_users print_job.list_users do |list_user|
	json.(list_user, :id, :total_users)
	json.users_data list_user.user_datum do |user_datum|
		json.(user_datum, :id, :status)
		if user_datum.user.present?
			json.(user_datum, :user)
		end
		json.(user_datum, :data, :created_at, :updated_at)
	end
	json.(list_user, :created_at, :updated_at)
end

json.extract! print_job, :created_at, :updated_at
