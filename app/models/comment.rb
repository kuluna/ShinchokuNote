class Comment < ApplicationRecord
  acts_as_paranoid

  validates :text, presence: true
  validates :to_note, presence: true

  enum anonimity: {
    secret: 0,
    open: 1
  }, _suffix: true

  belongs_to :from_user,
             class_name: 'User',
             foreign_key: 'from_user_id',
             optional: true
  belongs_to :to_note, class_name: 'Note', foreign_key: 'to_note_id'
  belongs_to :response_post,
             class_name: 'Post',
             foreign_key: 'response_id',
             optional: true
end
