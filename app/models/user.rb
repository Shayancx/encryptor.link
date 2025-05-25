class User < ApplicationRecord
  has_secure_password
  
  validates :email, presence: true, uniqueness: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: "must be a valid email address" }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
  before_save :downcase_email
  
  private
  
  def downcase_email
    self.email = email.downcase
  end
end

def self.authenticate(email, password)
  user = find_by(email: email.downcase)
  return user if user && user.authenticate(password)
  nil
end 

# app/models/user.rb        

# app/models/user.rb
# app/models/user.rb  
def self.find_by_email(email)


  find_by(email: email.downcase)
end

def self.create_with_password(email, password)
  create(email: email.downcase, password: password)
end

def self.update_password(user_id, new_password)
  user = find(user_id)
  user.update(password: new_password) if user
end