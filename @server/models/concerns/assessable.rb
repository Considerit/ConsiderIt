module Assessable
  extend ActiveSupport::Concern

  included do 
    has_one :assessment, :as => :assessable, :dependent => :destroy
    has_many :requests, :class_name => "Assessable::Request", :through => :assessment, :dependent => :destroy
    has_many :claims, :class_name => "Assessable::Claim", :through => :assessment, :dependent => :destroy

    class_attribute :assessable_fields
    class_attribute :assessable_objects
  end

  def assessable?
    true
  end

end