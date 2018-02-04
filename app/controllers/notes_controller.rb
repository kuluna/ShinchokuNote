class NotesController < ApplicationController
  before_action :note_user_collection, only:[:new, :show, :create, :update, :destroy]

  def index
    #Userのshowアクションと同じなのでリダイレクト
    redirect_to user_path(params[:user_id])
  end

  def new
    @note = @user.notes.new
  end

  def show

  end

  def create
    @note = @user.notes.new(get_notes_params)
    if @note.save
      #保存成功
      redirect_to root_path
    else
      #やりなおし
      render 'new'
    end
  end

  def edit

  end

  def update

  end

  def destroy

  end

  private
    #User取得
    def note_user_collection
      @user = User.find_by(screen_name: params[:user_id].to_s)
      render_404 and return if @user.nil?
      redirect_to root_path if current_user != @user
    end

    #Note取得
    def get_note
      @note = Note.find_by(id: params[:note_id])
      render_404 and return if @note.nil?
    end

    #Noteのパラメータを安全に取り出す
    def get_notes_params
      params.require(:note).permit(:type, :name, :desc)
    end
end
