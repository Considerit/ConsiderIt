task :migrate_proposal_description_fields => :environment do 

  # Proposal.where("description_fields is not NULL AND description_fields != '[]'").each do |p|
  Proposal.where("description_fields is not NULL AND description_fields != '[]'").each do |p|

    flds = JSON.load(p.description_fields)
    fields = []
    fields_with_group = []
    flds.each do |fld|
      if fld["label"] && fld["html"] && fld["label"].length > 0 && fld["html"].length > 0
        fields.append fld 
      elsif fld["group"] || fld[:group]
        fields_with_group.append fld 
      end
    end

    next if fields.length == 0 && fields_with_group.length == 0 

    new_description = p.description || ""

    fields.each do |fld|
      new_description += "<div style='margin-top:24px'>"
      new_description += "<h2 style='font-weight:700;font-size:24px;margin-bottom:18px'>#{fld['label']}</h2>"
      new_description += fld['html']
      new_description += "</div>"
    end

    fields_with_group.each do |fld|

      new_description += "<div style='margin-top:24px'>"
      new_description += "<h2 style='font-weight:700;font-size:24px;margin-bottom:18px'>#{fld['group']}</h2>"
      fld['items'].each do |item|
        new_description += "<h3 style='font-weight:500;font-size:22px;margin-bottom:18px'>#{item['label']}</h2>"
        new_description += item['html']
      end
      new_description += "</div>"
    end

    p.description = new_description
    p.save

  end




end