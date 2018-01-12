module UsersHelper
  include ApplicationHelper

  #Omniauth Twitterを用いた認証
  def twitter_login(auth)
    #authからデータ取り出し
    twitter_id = auth.uid
    token = auth.credentials.token
    secret = auth.credentials.secret

    #もし存在しなかったらユーザを作成する
    user = User.find_or_create_by(twitter_id: twitter_id)

    #ユーザーの情報を更新
    user.url = auth.info.urls.Twitter
    user.thumb_url = get_fullsize_thumb_uri(auth.info.image)
    user.screen_name = auth.info.nickname
    user.name = auth.info.name
    user.save

    if logged_in? && twitter_id != master_user_id
      #ログインしていたら　マスタユーザのグループリストを更新
      group_info = get_user_group_info
      group_info[twitter_id] = {"token": token, "secret": secret}
      set_user_group_info(group_info)
    else
      #ログインしていなかったら　userをマスタユーザに指定
      set_master_user(twitter_id, token, secret)
    end

    #選択ユーザ(カレントユーザ)を変更
    change_current_user(twitter_id)
  end

  #Cookieに保存された認証情報が正しいものであるか
  #(Twitter IDとAPI User Token, API User Secretsの認証)
  def check_cookie(twitter_id)
    raise NotImplementedError.new("Function check_cookie() has not made yet.")
  end

  #現在ログインしているユーザのidを全て取得する
  def logged_in_user_ids
    return [] if master_user.nil?
    users = get_user_group_info.keys
    users.push(master_user_id)
    return users
  end
  #現在ログインしているユーザを全て取得する
  def logged_in_users
    users = []
    logged_in_user_ids.each do |id|
      users.push(User.find_by(twitter_id: id))
    end
    return users
  end

  #マスタユーザの情報（IDとトークンの入ったHash）を取得する
  def master_user_info
    #キャッシュがあればそれを返す
    return @master_user_info_cache if !(@master_user_info_cache.nil?)
    if cookies.permanent.signed[:masteruserinfo].nil?
      #cookieが存在しなければnilを返す
      return nil
    else
      #存在すればJsonからhashを生成
      hash = JSON.parse(cookies.permanent.signed[:masteruserinfo])
      #マスタユーザのデータは唯一である（そうでない場合をはじく）
      return nil if hash.size != 1
      #最後キャッシュに保存して返す
      return @master_user_info_cache = hash
    end
  end
  #マスタユーザのTwitter IDを取得する
  def master_user_id
    master_user_info.nil? ? nil : master_user_info.keys.first
  end
  #マスタユーザを取得する
  def master_user
    return nil if master_user_id.nil?
    @master_user ||= User.find_by(twitter_id: master_user_id)
  end
  #マスタユーザのtokenを取得する
  def master_user_token
    master_user_info.nil? ? nil : master_user_info[master_user_id]["token"]
  end
  #マスタユーザのsecretを取得する
  def master_user_secret
    master_user_info.nil? ? nil : master_user_info[master_user_id]["secret"]
  end

  #現在選択中のユーザのTwitter IDを取得する
  def current_user_id
    cookies.permanent.signed[:currentuserid]
  end
  #現在選択中のユーザを取得する
  def current_user
    return nil if current_user_id.nil?
    @current_user ||= User.find_by(twitter_id: current_user_id)
  end

  #ログインしているかどうかを返す
  def logged_in?
    !(current_user.nil?) && !(master_user.nil?)
  end

  #adminユーザかどうかを返す
  def admin?
    current_user.admin?
  end

  #ログアウトする
  def logout_user(twitter_id)
    if twitter_id == master_user_id
      #全ユーザログアウト
      cookies.delete(:currentuserid)
      cookies.delete(:masteruserinfo)
    else
      #そのユーザだけ連携解除
      userinfo = get_user_group_info
      userinfo.delete(twitter_id)
      set_user_group_info(userinfo)
    end

  end

  private
    #マスタユーザを変更する
    def set_master_user(twitter_id, token, secret)
      masteruserinfo = {}
      masteruserinfo[twitter_id] = {token: token, secret: secret}
      cookies.permanent.signed[:masteruserinfo] = JSON.generate(masteruserinfo)
    end

    #現在選択中のユーザを変更する
    def change_current_user(twitter_id)
      #そのユーザがユーザ情報テーブル内に存在しなかったらnilを返す（ログインできない）
      # ※currentuserは変わらない
      raise NotLoggedInError if !(logged_in_user_ids.include?(twitter_id))
      cookies.permanent.signed[:currentuserid] = twitter_id
    end

    #現在のマスタユーザに付随するグループを取得
    def get_user_group_info
      #まだ情報が登録されていなければ空のHashを返す
      return {} if master_user.user_group_info.nil?
      #パスワードはOAuthシークレット
      pass = master_user_secret
      json = decrypt_data(master_user.user_group_info, pass, master_user.salt_8byte)
      JSON.parse(json)
    end
    #現在のマスタユーザに付随するグループを設定
    def set_user_group_info(group_info)
      #パスワードはOAuthシークレット
      pass = master_user_secret
      json = JSON.generate(group_info)
      master_user.user_group_info = encrypt_data(json, pass, master_user.salt_8byte).force_encoding("UTF-8")
      master_user.save!
    end
end

class NotLoggedInError < StandardError; end
