class Message

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :sendername, :sender, :recipient, :subject, :body

  validates :recipient, :sender, :subject, :body, :presence => true
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def senderName
    @sender if @sendername.nil?
    @sendername 
  end

  def addressedTo
    User.find @recipient
  end
end