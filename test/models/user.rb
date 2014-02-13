class User < ActiveRecord::Base
  belongs_to :group

  def id
    1
  end

  sync :all
  sync_scope :cool, -> { where(cool: true) }
  sync_scope :in_group, ->(group) { where(group_id: group.id)}
  sync_scope :with_group_id, ->(group_id) { where(group_id: group_id)}
  sync_scope :with_min_age_in_group, ->(age, group_id) { where(group_id: group_id).where(["age >= ?", age])}
end

class UserWithoutScopes < ActiveRecord::Base
  self.table_name = :users
  sync :all
end

class UserWithOneScope < ActiveRecord::Base
  self.table_name = :users
  sync :all
  sync_scope :old, -> { where(age: 90) }
end