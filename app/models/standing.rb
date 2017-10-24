class Standing < ApplicationRecord
  belongs_to :channel
  
  # Store this standings record in past_standings table:
  def archive
    PastStanding.create!({:standing_id => self.id, :channel_id => self.channel_id, :rank => self.rank,
      :share => self.share, :count0 => self.count0, :count1 => self.count1, :tallied_at => self.tallied_at})
  end

end
