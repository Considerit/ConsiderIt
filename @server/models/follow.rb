class Follow < ActiveRecord::Base

  belongs_to :followable, :polymorphic=>true
  belongs_to :user

  scope :active, -> { where( :follow => true )  }

  def as_json(options={})
    options[:only] ||= [:followable_id, :followable_type, :follow, :explicit]
    super(options)
  end

  def notify?
    follow
  end

  def self.build_from(obj, user_id, follow = false)
    c = self.new
    c.followable_id = obj.id 
    c.followable_type = obj.class.name 
    c.follow = follow
    c.user_id = user_id
    c
  end

  def root_object
    begin 
      followable_type.constantize.find(followable_id)
    rescue
      pp "Could not find a #{followable_type} of id #{followable_id}"
    end
  end

  def self.purge
    Follow.find_all do |u|
      begin
        obj = u.root_object
      rescue
        u.destroy
      end

    end
  end


end
