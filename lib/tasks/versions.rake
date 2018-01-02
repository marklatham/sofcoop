namespace :versions do

  desc "Reduce clutter of incremental post edits."
  task compress_posts: :environment do
    
    Time.zone = "UTC"
    time_now = Time.now
#    puts "COMPRESS POSTS. TIME NOW: = " + time_now.inspect
    
#    latest = PaperTrail::Version.where("item_type = ? and records_merged IS NOT NULL", "Post").
#                                 order("created_at ASC").last
#    if latest
#      versions = PaperTrail::Version.
#      where("item_type = ? and created_at > ?", "Post", 10.minutes.until(latest.created_at)).
#      order(:item_id, :created_at)
#    else
      versions = PaperTrail::Version.where("item_type = ?", "Post").order(:item_id, :created_at)
#    end
    
#    puts "PROCESSING #{versions.size.to_s} POSTS"
    updates = []
    for version in versions
#      puts "VERSION #{version.id.to_s}"
      if updates.empty?
        if version.event == "update" && version.changeset.keys == ["body", "updated_at"]
          updates << version
          this_item_id = version.item_id
          this_whodunnit = version.whodunnit
#          puts "ITEM #{this_item_id} & USER #{this_whodunnit}"
        end
        next
      end
      if  version.event == "update" &&
          version.changeset.keys == ["body", "updated_at"] &&
          version.item_id == this_item_id &&
          version.whodunnit == this_whodunnit
        updates << version
#        puts "INCLUDE #{version.id.to_s}"
      else
        compress(updates) if updates.size > 1
        updates = []
      end
    end
    compress(updates) if updates.size > 1
    
  end
  
  def compress(updates)
#    puts "#{updates.size.to_s} UPDATES:"
#    p updates
    previous = updates[0]
    for update in updates[1..-1]
      update_first_created = update.first_created_at || update.created_at
      previous_first_created = previous.first_created_at || previous.created_at
      merge(previous, update) if update_first_created < 1.hour.since(previous.created_at) &&
                                 update.created_at < 10.hours.since(previous_first_created)
      previous = update
#      puts "PREVIOUS:"
#      p previous
    end
  end
  
  def merge(u0, u1)
#    puts "CANDIDATES:"
#    p u0
#    p u1
#    p u0.changeset[:body][1]
#    p u1.changeset[:body][0]
    if [u0.item_type, u0.item_id, u0.event, u0.whodunnit, u0.changeset[:body][1]] !=
       [u1.item_type, u1.item_id, u1.event, u1.whodunnit, u1.changeset[:body][0]] ||
       u0.created_at > u1.created_at
      puts "MISMATCH -- NOT MERGED"
    else
      u1.object = u0.object
      u1.object_changes = "---\nbody:\n- " + translate(u0.changeset[:body][0]) + 
        "\n- " + translate(u1.changeset[:body][1]) + "\nupdated_at:\n- " + 
        u0.changeset[:updated_at][0].strftime("%Y-%m-%d %H:%M:%S") + ".000000000 Z\n- " + 
        u1.changeset[:updated_at][1].strftime("%Y-%m-%d %H:%M:%S") + ".000000000 Z\n"
      merged0 = u0.records_merged || 0
      merged1 = u1.records_merged || 0
      u1.records_merged = merged0 + merged1 + 1
      u1.first_created_at = u0.first_created_at || u0.created_at
      u1.save
      u0.destroy!
#      puts "MERGED"
    end
  end
  
  def translate(string)
    case string
      when nil then ""
      when "" then "''"
      else string
    end
  end
  
end
