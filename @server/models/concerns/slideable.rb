module Slideable
  extend ActiveSupport::Concern

  included do
    has_many :opinions, :as => :statement, :dependent => :destroy
  end
end
