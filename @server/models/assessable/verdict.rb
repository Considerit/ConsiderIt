class Assessable::Verdict < ActiveRecord::Base

  has_many :assessments
  has_many :claims

  acts_as_tenant :account

  has_attached_file :icon, 
    :styles => { 
      :square => "100x100#"
    },
    :processors => [:thumbnail, :compression]

  validates_attachment_content_type :icon, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  def formatVerdict
    if id == -1
      'No claims'
    else
      short_name
    end
  end


  def as_json(options={})
    result = super(options)
    result['key'] = "verdict/#{id}"
    result
  end


end