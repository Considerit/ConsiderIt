namespace :admin do
  desc "Clear duplicate point similarities"
  task :clear_duplicate_point_similarities => :environment do
    dups = PointSimilarity.where('p1_id=p2_id')
    pp dups
    if dups.length > 0
      #dups.destroy
    end
  end

end