class Ballot
  attr_reader :session_votes

  def initialize
    @session_votes = []
  end

  def add_vote(vote)
    @session_votes << vote
  end
end
