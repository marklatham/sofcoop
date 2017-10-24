namespace :votes do

  desc "Fill in days & level for recent votes."
  task process: :environment do
    Time.zone = "Pacific Time (US & Canada)"
    time_now = Time.now
    puts "Time now = " + time_now.inspect
    
    votes = Vote.where("days IS NULL").order(:id)
    puts votes.size.to_s + " new votes"
    
    for vote in votes
      if previous_vote = Vote.where("ip = ? and created_at < ?",
                                        vote.ip, vote.created_at).order("created_at").last
        vote.days = (vote.created_at.in_time_zone.to_date - previous_vote.created_at.in_time_zone.to_date).to_f
      else
        vote.days = -1
      end
      
      if auth = Auth.where("user_id = ? and created_at < ?",
                             vote.user_id, vote.created_at).order("created_at").last
        vote.level = auth.level
      end
      
      vote.save
    end
  end


  desc "Tally votes for the next day."
  task tally: :environment do
    
    # Tally cutoff_time is the next midnight after the last tally cutoff time,
    # which should be the same in both current and archived standings tables.
    # cutoff_time must also be before Time.now.
    
    Time.zone = "Pacific Time (US & Canada)"
    time_now = Time.now
    puts "Time now = " + time_now.inspect
    standing_tallied_at = Standing.maximum(:tallied_at) if Standing.any?
    past_standing_tallied_at = PastStanding.maximum(:tallied_at) if PastStanding.any?
    puts "standing_tallied_at = " + standing_tallied_at.to_s
    puts "past_standing_tallied_at = " + past_standing_tallied_at.to_s
    
    if standing_tallied_at
      latest_tallied_at = standing_tallied_at
      if past_standing_tallied_at
        unless standing_tallied_at == past_standing_tallied_at # Normal case is ==
          puts "Warning: standing_tallied_at = " + standing_tallied_at.to_s
          puts "not same as past_standing_tallied_at = " + past_standing_tallied_at.to_s
          if standing_tallied_at > past_standing_tallied_at
            puts "Current standings seem not archived => archiving..."
            for standing in Standing.all
              standing.archive
            end
          else # i.e. standing_tallied_at < past_standing_tallied_at
            latest_tallied_at = past_standing_tallied_at
            puts "Warning: archived standings later than current standings."
          end
        end
      else # i.e. past_standing_tallied_at does not exist
        puts "Warning: no past_standing_tallied_at found."
      end
    else # i.e. standing_tallied_at does not exist
      puts "Warning: no standing_tallied_at found."
    end
    
    if latest_tallied_at
      # Usually 24 hours to next cutoff, but this allows +- 12 hours for unusual situations:
      next_day = 36.hours.since(latest_tallied_at)
    else
      # If no prior tally output exists, default to next_day = now:
      next_day = time_now
    end
    # Set cutoff_time = the midnight before next_day:
    cutoff_time = Time.new(next_day.year, next_day.month, next_day.day, 0, 0, 0)
    puts "Tally cutoff = " + cutoff_time.inspect
    
    if cutoff_time > time_now
      puts "It's too soon to tally!"
    else
      calc_standings(cutoff_time)  # ***MAIN ROUTINE: Method defined below.
    end
    AdminMailer.votes_tally(cutoff_time).deliver
  end
  
  
  # Subroutine to calculate channel standings from votes:
  def calc_standings(cutoff_time)
    
    parameter = Parameter.where("as_of < ?", cutoff_time).order(:as_of).last
    
    standings = Standing.all.to_a
    unless standings.any?
      puts "Warning: no standings found. Generating them from displayed channels."
      channels = Channel.where("display_id > 0")
      if channels.any?
        for channel in channels
          Standing.create!(channel_id: channel.id, share: 1.0)
        end
        standings = Standing.all.to_a
      else
        puts "Alert: no standings or displayed channels -- nothing to do!  :-("
        return
      end
    end
    if standings.any?
      puts "Found " + standings.size.inspect + " standings."
    else
      puts "Alert: Found no standings!"
      return
    end
    
    oldest_time = (parameter.days_valid + 1).days.until(cutoff_time)
    puts "oldest_time = " + oldest_time.inspect
    votes_auth = Vote.where("created_at > ? and created_at < ? and level > ?",
                                oldest_time,       cutoff_time,    parameter.ip_level)
                     .order(:user_id, :channel_id, created_at: :desc).to_a
    votes_non_auth = Vote.where("created_at > ? and created_at < ? and (level IS NULL or level <= ?)",
                                   oldest_time,       cutoff_time,               parameter.ip_level)
                     .order(:ip,      :channel_id, created_at: :desc).to_a
    if votes_auth.any?
      puts "Found " + votes_auth.size.to_s + " votes_auth."
    else
      puts "Found no votes_auth."
    end
    if votes_non_auth.any?
      puts "Found " + votes_non_auth.size.to_s + " votes_non_auth."
    else
      puts "Found no votes_non_auth."
    end
    
    # Don't count votes_non_auth with same ip as votes_auth:
    votes_auth_ips = votes_auth.map(&:ip).uniq.sort
    puts votes_auth_ips.inspect
    puts votes_non_auth.inspect
    votes_to_keep = []
    for vote in votes_non_auth
      puts vote.inspect
      votes_to_keep << vote unless votes_auth_ips.include?(vote.ip)
    end
    votes_non_auth = votes_to_keep
    puts votes_non_auth.inspect
    puts votes_non_auth.size.to_s + " votes_non_auth left."
    
    # In votes_auth, only count the latest vote from each user on each channel.
    # For each [user_id, channel_id], votes are in reverse chronological order,
    # so keep the first one in each group:
    if votes_auth.any?
      votes_to_keep = []
      keep_vote = votes_auth[0]
      votes_to_keep << keep_vote
      for vote in votes_auth
        unless vote.user_id ==  keep_vote.user_id &&  vote.channel_id == keep_vote.channel_id
          keep_vote = vote
          votes_to_keep << keep_vote
        end
      end
      votes_auth = votes_to_keep
      puts votes_auth.size.to_s + " latest votes_auth for tallying."
    end
    
    # In votes_non_auth, only count the latest vote from each ip on each channel.
    # For each [ip, channel_id], votes are in reverse chronological order,
    # so keep the first one in each group:
    if votes_non_auth.any?
      votes_to_keep = []
      keep_vote = votes_non_auth[0]
      votes_to_keep << keep_vote
      for vote in votes_non_auth
        unless vote.ip ==  keep_vote.ip &&  vote.channel_id == keep_vote.channel_id
          keep_vote = vote
          votes_to_keep << keep_vote
        end
      end
      votes_non_auth = votes_to_keep
      puts votes_non_auth.size.to_s + " latest votes_non_auth for tallying."
    end
    
    votes = votes_auth | votes_non_auth
    
    # Make sure shares are nonnegative whole numbers, not all zero:
    for standing in standings
      standing.share = standing.share.round
      if standing.share < 0.0
        standing.share = 0.0
      end
    end
    
    if standings.sum(&:share) <= 0.0
      for standing in standings
        standing.share = 1.0
      end
    end
    
    # Calculate count0 (# votes for share or more) and count1 (# votes for share+1 or more) for each standing:
    for standing in standings
      standing.count0 = count_votes(cutoff_time, votes, standing, 0.0, parameter)
      standing.count1 = count_votes(cutoff_time, votes, standing, 1.0, parameter)
      puts standing.channel.name + " Count0: " + standing.count0.inspect
      puts standing.channel.name + " Count1: " + standing.count1.inspect
    end
    
    # standing_to_increase is the standing record that most deserves to have its share increased by 1:
    standing_to_increase = standings.max{|a,b| a.count1 <=> b.count1 }
    # Can only reduce a share if it's positive, so:
    standings_pos = standings.find_all {|s| s.share > 0.0 }
    # standing_to_decrease is the standing record that most deserves to have its share decreased by 1:
    standing_to_decrease = standings_pos.min {|a,b| a.count0 <=> b.count0 }
    
    # If shares sum to more than 100 (which shouldn't happen, but just in case), decrease 1 at a time:
    while standings.sum(&:share) > 100.0
      standing_to_decrease.share -= 1.0
      standing_to_decrease.count1 = standing_to_decrease.count0
      standing_to_decrease.count0 = count_votes(cutoff_time, votes, standing_to_decrease, 0.0, parameter)
      
    #  standing_to_increase = standings.max{ |a,b| a.count1 <=> b.count1 }
      standings_pos = standings.find_all{ |s| s.share > 0.0 }
      standing_to_decrease = standings_pos.min{ |a,b| a.count0 <=> b.count0 }
    end
    standing_to_increase = standings.max{ |a,b| a.count1 <=> b.count1 }
    
    # If shares sum to less than 100 (e.g. when first website[s] added), increase 1 at a time:
    while standings.sum(&:share) < 100.0
      standing_to_increase.share += 1.0
      standing_to_increase.count0 = standing_to_increase.count1
      standing_to_increase.count1 = count_votes(cutoff_time, votes, standing_to_increase, 1.0, parameter)
      
      standing_to_increase = standings.max{ |a,b| a.count1 <=> b.count1 }
    #  standings_pos = standings.find_all{ |s| s.share > 0.0 }
    #  standing_to_decrease = standings_pos.min{ |a,b| a.count0 <=> b.count0 }
    end
    standings_pos = standings.find_all{ |s| s.share > 0.0 }
    standing_to_decrease = standings_pos.min{ |a,b| a.count0 <=> b.count0 }
    
    # ***MAIN LOOP: Adjust shares until highest count1 <= lowest count0
    # i.e. find a cutoff number of votes (actually a range of cutoffs)
    # where shares sum to 100.0 using that same cutoff to determine each website's share.
    # This is like a stock market order matching system. Each count1 is a bid; each count0 is an offer.
    # If the highest bid is higher than the lowest offer, then a trade of 1% happens:
    
    while standing_to_decrease.count0 < standing_to_increase.count1
      # Move one percent share from standing_to_decrease to standing_to_increase:
      
      standing_to_decrease.share -= 1.0
      standing_to_decrease.count1 = standing_to_decrease.count0
      standing_to_decrease.count0 = count_votes(cutoff_time, votes, standing_to_decrease, 0.0, parameter)
      
      standing_to_increase.share += 1.0
      standing_to_increase.count0 = standing_to_increase.count1
      standing_to_increase.count1 = count_votes(cutoff_time, votes, standing_to_increase, 1.0, parameter)
      
      standings_pos = standings.find_all{ |r| r.share > 0.0 }
      standing_to_decrease = standings_pos.min{ |a,b| a.count0 <=> b.count0 }
      standing_to_increase = standings.max{ |a,b| a.count1 <=> b.count1 }
    end
    
    # Share calculations are now completed, so sort & store standings:
    standings.sort! do |a,b|
      [b.share, b.count1, b.created_at] <=> [a.share, a.count1, a.created_at]
    end
    rank_sequence = 0
    for standing in standings
      rank_sequence += 1
      standing.rank = rank_sequence
      standing.tallied_at = cutoff_time
      standing.save     # => Standings table
      standing.archive  # => PastStandings table
    end
    
  end
  
  
  # Subroutine to count (time-decayed) votes for shares >= cutoff_share = standing.share + increment:
  def count_votes(cutoff_time, votes, standing, increment, parameter)
    
    cutoff_share = standing.share + increment
    
    count = 0.0
    for vote in votes
      if vote.channel_id == standing.channel_id && vote.share
        
        # Time decay of vote:
        days_old = (cutoff_time.to_date - vote.created_at.to_date).to_i
        if days_old < parameter.days_full_value
          decayed_weight = 1.0
        elsif days_old < parameter.days_valid
          decayed_weight = ( parameter.days_valid - days_old ) /
                           ( parameter.days_valid - parameter.days_full_value )
        else
          decayed_weight = 0.0
        end
        
        if vote.share < 0.1
          # This is to catch the special case of vote.share = 0.0 -- no interpolation.
          if cutoff_share < 0.1
            support_fraction = 1.0
          else
            support_fraction = 0.0
          end
        elsif vote.share > cutoff_share + 0.5*parameter.interpolation_range
          support_fraction = 1.0
        elsif vote.share < cutoff_share - 0.5*parameter.interpolation_range
          support_fraction = 0.0
        else
          support_fraction = 0.5 + ( (vote.share - cutoff_share) / parameter.interpolation_range )
        end
        
        auth_level = parameter.ip_level
        auth_level = vote.level if vote.level
        
        count += decayed_weight * support_fraction * auth_level
      end
    end
    
    # This is designed to encourage competition by handicapping larger shares:
    adjusted_count = count / ( parameter.spread**(cutoff_share*0.01) )
    puts standing.channel.name + " adjusted count at share = " + standing.share.to_s +
                      " & increment = " + increment.to_s + " is " + adjusted_count.to_s
    return adjusted_count
  end
  
end
