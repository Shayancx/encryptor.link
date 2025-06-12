# Allow deep nesting of parameters
if Rails.env.development?
  ActionController::Parameters.permit_all_parameters = false
  ActionController::Parameters.action_on_unpermitted_parameters = :log
end
