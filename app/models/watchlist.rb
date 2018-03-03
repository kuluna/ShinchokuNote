class Watchlist < ApplicationRecord
  belongs_to :from_user, class_name: 'User', foreign_key: 'from_user_id'
  belongs_to :to_note, class_name: 'Note', foreign_key: 'to_note_id'
end
