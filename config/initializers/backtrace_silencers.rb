

# Rails.backtrace_cleaner.add_silencer do |line|
#   pp (line !~ line.gsub(Rails.root, '')), line, Rails.root
#   (line !~ Rails::BacktraceCleaner::APP_DIRS_PATTERN)
# end

Rails.backtrace_cleaner.remove_silencers!
Rails.backtrace_cleaner.add_filter { |line| line.gsub(Rails.root.to_s, '<root>') }
Rails.backtrace_cleaner.add_silencer { |line| line.index('<root>').nil? and line.index('/') == 0 }
Rails.backtrace_cleaner.add_silencer { |line| line.index('<root>/vendor/') == 0 }
