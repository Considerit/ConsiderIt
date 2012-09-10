namespace :metrics do
  desc "Based on existing data, initialize the activities table"

  task :basic => :environment do
    puts "Number\tName\tpositions\tpoints\tinclusions\tInclusions per point\tInclusions per position"
    Proposal.where(:domain_short => 'WA State').each do |p|
      printf("%i\t%s\t%i\t%i\t%i\t%.2f\t%.2f\n",
        p.designator,p.short_name,p.positions.published.count,p.points.published.count,p.inclusions.count,
        p.inclusions.count.to_f / p.points.published.count,
        p.inclusions.count.to_f / p.positions.published.count)
    end
  end
end