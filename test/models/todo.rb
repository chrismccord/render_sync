class Todo < ActiveRecord::Base
  belongs_to :user

  sync :all
  sync_scope :complete, -> { where(complete: true) }
  sync_scope :by_user, ->(user) { where(user_id: user.id) }
  sync_scope :with_user_id, ->(user_id) { where(user_id: user_id) }
end