module ActsAsTaggableOn
  class Tagging
    # reopen the class
    Tagging.class_eval do
      acts_as_tenant(:account)
    end
  end
  class Tag
    # reopen the class
    Tag.class_eval do
      acts_as_tenant(:account)
    end
  end

end