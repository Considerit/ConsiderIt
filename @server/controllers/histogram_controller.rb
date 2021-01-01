class HistogramController < ApplicationController

  def update
    proposal = Proposal.find params[:id]

    positions = params[:positions]
    hash = params[:hash]



    histocache = JSON.parse((proposal.histocache || '{}'))

    if !histocache.include?(hash)
      histocache[hash] = positions
      proposal.histocache = JSON.dump histocache
      proposal.save
    end 
    render :json => []
  end

end
