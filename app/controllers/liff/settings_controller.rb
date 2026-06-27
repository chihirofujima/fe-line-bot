class Liff::SettingsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :update, :current ]
  layout "liff"

  def index
  end

  def current
    user = User.find_by(line_user_id: session[:line_user_id])
    return render json: { error: "ユーザーが見つかりません" }, status: :not_found unless user

    setting = DeliverySetting.find_or_initialize_by(user_id: user.id)
    render json: setting
  end

  def update
    user = User.find_by(line_user_id: session[:line_user_id])
    return render json: { error: "ユーザーが見つかりません" }, status: :not_found unless user

    setting = DeliverySetting.find_or_initialize_by(user_id: user.id)
    is_new_setting = setting.new_record?

    if setting.update(delivery_setting_params)
      if is_new_setting
        next_time = DeliveryTimeCalculator.call(setting)
        DeliverQuestionJob.set(wait_until: next_time).perform_later(user.id) if next_time
      end
      render json: { message: "保存しました" }, status: :ok
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def delivery_setting_params
    params.permit(:frequency, :delivery_time_1, :delivery_time_2)
  end
end
