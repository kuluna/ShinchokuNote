class UsersController < ApplicationController
  before_action :check_logged_in, only: %i[notifications notifications_checked recommended_users]
  before_action -> { load_user_as_me_or_admin :id },
                only: %i[edit update destroy]
  before_action -> { load_user_as_me_or_admin :user_id }, only: :leave
  before_action -> { load_user :id }, only: :show
  before_action :load_notifications, only: :notifications
  before_action :load_twitter_friends, only: :recommended_users

  def index
    # Only admin
    unless admin?
      redirect_to root_path
      return
    end
    @users = User.all
  end

  def new
    if params[:force_login] == 'true'
      redirect_to '/auth/twitter?force_login=true'
    else
      redirect_to '/auth/twitter'
    end
  end

  def edit
    # before_actionですでに@userは取得済みなのでなにもしない
  end

  def update
    if @user.update_attributes(users_params)
      # 保存成功
      redirect_to root_path
    else
      # やりなおし
      render 'edit'
    end
  end

  def show
    # before_actionですでに@userは取得済みなのでなにもしない
  end

  def leave
    # before_actionですでに@userは取得済みなのでなにもしない
  end

  def destroy
    logout_user @user
    @user.destroy
    redirect_to root_path
  end

  def login
    # auth情報を取り出しログイン
    auth = request.env['omniauth.auth']
    # ログインか新規登録かのチェック
    if User.find_by(twitter_id: auth.uid).nil?
      # ユーザーが存在していない
      user = User.with_deleted.find_by(twitter_id: auth.uid)
      if user.nil?
        # 新規登録時の挙動
        unless MYCONF['allow_user_register']
          # 新規登録不可の場合、そのせつを出力
          render 'static_pages/register_denyed'
          return
        end
        flash[:success] = "はじめまして、@#{auth[:info][:nickname]}さん！"
      else
        # ユーザーが一度退会し、再度登録した時の挙動
        # データの復元
        user.restore(recursive: true)
        flash[:success] = "一度退会済みのユーザーです。過去のユーザーデータを復元しました。おひさしぶりです、@#{auth[:info][:nickname]}さん！"
      end
    else
      flash[:success] = "こんにちは、@#{auth[:info][:nickname]}さん！"
    end
    twitter_login(auth)
    redirect_to root_path
  end

  def logout
    # cookieを削除すればログアウト処理に
    logout_user(current_user)
    flash[:success] = 'ログアウトしました'
    redirect_back(fallback_location: root_path)
  end

  def home
    # 未ログイン状態ならばstatic_pages#homeを描画
    render 'static_pages/home' unless logged_in?
    
    @announces = Announce.where('created_at > ?', Time.now.yesterday)
                         .order('created_at DESC')
  end

  def switchuser
    change_current_user_id(params[:id])
    flash[:success] = 'ユーザーを切り替えました'
    redirect_back(fallback_location: root_path)
  end

  def updateuser
    user_info_update
    redirect_back fallback_location: user_path(current_user.screen_name)
  end

  def notifications
    # @notifications はbefore_actionですでに読み込んでいる
    current_user.saw_notifications_at = Time.now
    current_user.save!

    return if @notifications.empty?
  end

  def notifications_checked
    # 通知チェック処理
    current_user.checked_notifications_at = Time.now
    current_user.save!

    redirect_to notifications_path
  end

  def recommended_users; end

  private

  # Userのパラメータを安全に取り出す
  def users_params
    params.require(:user).permit(:desc, :comment_webpush_enabled, :shinchoku_dodeska_webpush_enabled)
  end
end
