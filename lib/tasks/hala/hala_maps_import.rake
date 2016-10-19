task :hala_maps, [:sub] => :environment do |t, args|
  # sub = args[:sub] || 'hala'


  # load info file from HALA team
  fname = "lib/tasks/hala/hala_data.csv"
  begin
    CSV.read(fname)
    encoding = 'utf-8'
  rescue
    encoding = 'windows-1251:utf-8'
  end

  clusters = {
    'Alignment with Mandatory Housing Affordability principles' => ['In general, the draft zoning changes for {NEIGHBORHOOD} accurately reflects the Principles to Guide MHA Implementation.'],
    'Commercial Areas' => [
      'The location and placement of the commercial zones is reasonable and appropriate as a way to implement MHA in {NEIGHBORHOOD}.',
      'The height and scale that would be allowed by the draft zoning for commercial areas is reasonable and appropriate as a way to implement MHA in {NEIGHBORHOOD}.'
    ],
    'Multi-family Residential Areas' => [
      'The location and placement of the multi-family zones is reasonable and appropriate as a way to implement MHA in {NEIGHBORHOOD}.',
      'The height and scale that would be allowed by the draft zoning for multi-family areas is reasonable and appropriate as a way to implement MHA in {NEIGHBORHOOD}.'
    ],
    'Single Family Rezone Areas' => [
      'The Residential Small Lot (RSL) zone is in appropriate places to implement MHA in {NEIGHBORHOOD} while maintaining scale and character of single family areas.',
      'Places where Single Family is changed to Lowrise (LR) in {NEIGHBORHOOD} are appropriate to allow multi-family housing.'
    ],
    'Urban Village Expansions' => [
      'The draft urban village boundary is appropriate for the {NEIGHBORHOOD} area taking into account local factors and features.'
    ]
  }

  neighborhoods = []

  CSV.foreach(fname, 
    :headers => true, 
    :encoding => encoding, 
    :header_converters=> lambda {|f| f.strip},
    :converters => lambda {|f| f ? f.strip : nil}) do |row|

    neighborhoods.append({
      :name => row['neighborhood'],
      :url => row['url_of_map'],
      :include_expansion_question => row['include_expansion_question'].downcase == 'true'
    })

  end

  # create export file
  fields = ["cluster", "topic", "url", "description", "user"]

  CSV.open("lib/tasks/hala/hala_import.csv", "w") do |csv|
    csv << fields

    neighborhoods.each do |n|
      
      clusters.each do |cluster, questions|
        if cluster != 'Urban Village Expansions' || n[:include_expansion_question]

          questions.each do |question|
            url = n[:name].downcase.gsub(/ /, '_') + '--' + question.gsub(/\{NEIGHBORHOOD\}/, n[:name])
            url = url[0..60].gsub(/[ \(\)\.\,]+/, '-')
            csv << [cluster, question.gsub(/\{NEIGHBORHOOD\}/, n[:name]), url, n[:url], 'jesseca.brand@seattle.gov.ghost']
          end 
        end 
      end 
    end
  end
end


