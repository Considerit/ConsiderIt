task :LDA => :environment do
  data = []


  # for doing proposal-based topic modeling 
  # Subdomain.find_by_name('ainaalohafutures').proposals.each_with_index do |p, idx|
  #   wrd = "#{idx}: #{p.cluster} /// #{p.name}"
  #   if p.description
  #     wrd += " #{ActionView::Base.full_sanitizer.sanitize(p.description)}"
  #   end
  #   data.push wrd
  # end

  # for doing pro/con based topic modeling
  proposal = Subdomain.find_by_name('denverclimateaction').proposals.find_by_slug('it-is-urgent-that-denver-take-action-on-climate-change-major-goal')
  
  proposal.points.each_with_index do |p, idx|
    wrd = "#{idx}: #{p.nutshell}"
    if p.text
      wrd += " #{ActionView::Base.full_sanitizer.sanitize(p.text)}"
    end
    data.push wrd
  end



  mdl = Tomoto::LDA.new(tw: :one, min_cf: 3, rm_top: 5, seed: 42, k: 10)
  lem = Lemmatizer.new

  docs = []
  data.each do |line|
    ch = line.downcase.gsub('\n', ' ').gsub('"', '').gsub('--', '-').strip.split(/[[:space:]]+/)
    # TODO: expand contractions
    # todo: generate bigrams and trigrams
    wrds = []
    ch.each do |wrd|
      wrd = wrd.strip.sub(/[?.!,;]?$/, '')
      if wrd.length > 1 && !wrd.is_a?(Numeric)
        wrds.push lem.lemma(wrd)
      end
    end
    docs.push wrds
  end

  common_words = {}
  File.readlines('/Users/travis/Documents/code/ConsiderIt/lib/tasks/100_common_words.txt').each do |wrd|
    common_words[wrd.strip.downcase] = 1
  end

  all_statements_file = '/Users/travis/Documents/code/ConsiderIt/tmp/all_statements.txt'
  if !File.exists?(all_statements_file)

    words_by_frequency = {}
    all_statements = []

    Proposal.all.each do |p|
      line = "#{p.cluster} /// #{p.name}"
      if p.description
        line += " #{ActionView::Base.full_sanitizer.sanitize(p.description)}"
      end

      all_statements.push line
    end

    Point.all.each do |p|
      line = "#{p.nutshell}"
      if p.text
        line += " #{ActionView::Base.full_sanitizer.sanitize(p.text)}"
      end

      all_statements.push line
    end

    all_statements.each do |line|
      ch = line.downcase.strip.split(/[[:space:]]+/)

      words_by_frequency_p = {}
      ch.each do |wrd|
        wrd = wrd.strip
        if wrd.length > 1 && !wrd.is_a?(Numeric)
          wrd = lem.lemma(wrd)
          words_by_frequency_p[wrd] ||= 0
          words_by_frequency_p[wrd] += 1
        end
      end

      words_by_frequency_p.each do |k,v|
        words_by_frequency[k] ||= 0
        words_by_frequency[k] += 1
      end
    end

    words_by_frequency = words_by_frequency.to_a
    words_by_frequency.sort! { |a,b| b[1] - a[1] }
    File.open(all_statements_file, "wb") {|f| Marshal.dump(words_by_frequency, f)}

  else 
    File.open(all_statements_file, "rb") {|f| words_by_frequency = Marshal.load(f)} 
    pp 'loaded!', words_by_frequency[0..100]
  end

  words_by_frequency[0..100].each do |wrd|
    if !common_words.has_key?(wrd[0])
      pp "Strike: #{wrd[0]} (#{wrd[1]})"
      common_words[wrd[0]] = 1
    end
  end


  docs.each do |doc|

    filtered_doc = []
    doc.each do |wrd|
      if !common_words.has_key?(wrd)
        filtered_doc.push wrd
      end
    end
    mdl.add_doc filtered_doc
  end

  mdl.burn_in = 100
  mdl.train(0)


  puts "Num docs: #{mdl.num_docs}, Vocab size: #{mdl.used_vocabs.length}, Num words: #{mdl.num_words}"
  puts "Removed top words: #{mdl.removed_top_words}"
  puts "Training..."
  100.times do |i|
    mdl.train(10)
    puts "Iteration: #{i * 10}\tLog-likelihood: #{mdl.ll_per_word}"
  end

  puts mdl.summary
  puts "Saving..."
  # mdl.save(save_path)


  topic_map = {}

  mdl.docs.each_with_index do |doc, idx|
    # puts "Doc: #{data[idx]}"
    tops = doc.topics.to_a
    tops.sort! { |a,b| b[1] - a[1] }
    tops.each_with_index do |topic, rank|
      if rank < 1
        # puts "\t\t #{topic[0]} (#{topic[1]})"
        topic_map[topic[0]] ||= []
        topic_map[topic[0]].push ({
                  idx: idx,
                  match: topic[1],
                  str: data[idx]
                })
      end
    end
  end


  mdl.k.times do |k|
    next if !topic_map.has_key?(k)

    puts "\n\nTopic ##{k}"
    mdl.topic_words(k).each do |word, prob|
      if prob > 0.05
        puts "\t\t#{word}\t#{prob}"
      end
    end
    puts "\n"
    topic_map[k].each do |doc|
      puts "\tMatch (#{doc[:match]}): #{doc[:str][0..200]}"
    end



  end


end
