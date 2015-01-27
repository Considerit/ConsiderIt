Rails.backtrace_cleaner.add_filter { |line| line.gsub(Rails.root.to_s, '<root>') }
Rails.backtrace_cleaner.add_silencer { |line| line.index('<root>').nil? and line.index('/') == 0 }
Rails.backtrace_cleaner.add_silencer { |line| line.index('<root>/vendor/') == 0 }
