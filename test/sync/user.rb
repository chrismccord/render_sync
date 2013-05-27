class User

  def self.find(*args)
    self.new
  end

  def self.model_name
    "User"
  end

  def id
    1
  end
end
