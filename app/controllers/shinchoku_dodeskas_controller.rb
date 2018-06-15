class ShinchokuDodeskasController < ApplicationController
  include ShinchokuDodeskasHelper

  before_action -> { load_note :note_id }, only: %i[create toggle]

  def create
    # 権限確認
    unless user_can_see? @note, current_user
      render_403
      return
    end

    # 一日二回の投稿はできない
    if posted_shinchoku_dodeska_today?(@note, current_user)
      render_403
      return
    end

    @shinchoku_dodeska = ShinchokuDodeska.new
    if logged_in?
      @shinchoku_dodeska.from_user = current_user
    else
      @shinchoku_dodeska.from_addr =
        request.env['HTTP_X_FORWARDED_FOR'] ||
        request.remote_ip
    end
    @shinchoku_dodeska.to_note = @note
    @shinchoku_dodeska.save!

    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    @shinchoku_dodeska.destroy
  end
end
