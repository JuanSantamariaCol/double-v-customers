class Customer < ApplicationRecord
  include OutboxPublisher

  enum :person_type, { natural: 0, company: 1 }, prefix: :person

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :person_type, presence: true
  validates :identification, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 255 }
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :address, presence: true, length: { maximum: 500 }

  # Scopes
  scope :actives, -> { where(active: 1) }
  scope :inactives, -> { where(active: 0) }

  # Instance methods
  def active?
    active == 1
  end

  def soft_delete
    update(active: 0)
  end

  def restore
    update(active: 1)
  end
end
