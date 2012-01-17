class StudyData < ActiveRecord::Base
  belongs_to :user
  belongs_to :position
  belongs_to :point
  belongs_to :proposal
end
