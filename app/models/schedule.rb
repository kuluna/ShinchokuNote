class Schedule < Post
  acts_as_paranoid

  enum status: {
    undone: 0,
    done: 1
  }, _suffix: true
end
