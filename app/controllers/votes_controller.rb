class VotesController < ApplicationController

  def vote_for_channel
    share = params[:share]
    channel = Channel.find(params[:channel_id])
    ip = request.remote_ip
    agent = request.user_agent
    if current_user
      vote = Vote.create!(share: share, channel_id: channel.id, ip: ip, agent: agent,
                         user_id: current_user.id, is_member: current_user.is_member)
      unless current_user.is_member?
        flash[:notice] = 'Thank you for voting; but only votes from logged-in members will affect award shares.'
      end 
    else
      vote = Vote.create!(share: share, channel_id: channel.id, ip: ip, agent: agent)
      flash[:notice] = 'Thank you for voting; but only votes from logged-in members will affect award shares.'
    end
    ballot = find_ballot
    ballot.add_vote(vote)
    redirect_to root_path
  end

end
