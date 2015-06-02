task :dump_random2015 => :environment do
  subdomain = Subdomain.find(2087)


  f = open('lib/tasks/random2015/reviews.txt', 'w')
  for paper in subdomain.proposals.order(:id)
    f.puts('')    
    f.puts('================================================')
    f.puts("#{paper.slug.gsub('_', ' ').capitalize}: #{paper.name} ")
    f.puts('================================================')
    f.puts('')

    cons = paper.points.published.where(:is_pro => false)
    pros = paper.points.published.where(:is_pro => true)

    
    if cons.count == 0 
      f.puts('The PC didn\'t discuss any weaknesses of your submission beyond what was noted in the reviews.')
      f.puts("")              
    else
      f.puts('The PC considered the following weaknesses of your submission:')
      f.puts("")

      for con in cons
        p = "  - #{con.nutshell}#{con.text && con.text.length > 0 ? '...' + con.text : ''}"
        f.puts(p.gsub("\n", ' '))
        f.puts("")        
      end
    end


    if pros.count == 0 
      f.puts('The PC didn\'t discuss any strengths of your submission beyond what was noted in the reviews.')
    else
      f.puts('The PC considered the following strengths of your submission:')
      f.puts("")

      for pro in pros
        p = "  + #{pro.nutshell}#{pro.text && pro.text.length > 0 ? '...' + pro.text : ''}"
        f.puts(p.gsub("\n", ' '))
        f.puts("")
      end
    end

  end

end