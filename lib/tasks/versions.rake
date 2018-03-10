namespace :versions do

  desc "Hide versions with duplicated item_id."
  # Probably not needed any more, because superseded by code inserted into posts#create.
  # Defends against MySQL bug that will be gone in cluster version 8.0.0.
  # See https://stackoverflow.com/a/46628734/7356045
  task hide_dupes: :environment do
    versions = PaperTrail::Version.where("(event = ? OR event = ?) AND item_id > 0", "create", "destroy").order(:item_type, :item_id, :created_at)
    item_id = nil
    for version in versions
      if item_id && version.item_id == item_id && version.event == "create"
        hide_old_versions(version)
      else
        item_id = nil
      end
      if version.event == "destroy"
        item_id = version.item_id
      end
    end
  end
  
  def hide_old_versions(version)
    old_versions = PaperTrail::Version.where("item_type = ? AND item_id = ? AND created_at < ?", version.item_type, version.item_id, version.created_at)
    for old_version in old_versions
      old_version.item_id = 0  # Tried nil but not allowed.
      old_version.save
    end
    AdminMailer.hid_dupes(version).deliver
  end
  
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
#      puts "VERSION #{version.item_version_id.to_s}"
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
#        puts "INCLUDE #{version.item_version_id.to_s}"
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
      merge(previous, update) if update_first_created < 1.second.since(previous.created_at) &&
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

  desc "Populate newly created field version.item_version_id."
  task populate_item_version_id: :environment do
    versions = PaperTrail::Version.all.order(:item_type, :item_id, :created_at)
    previous = nil
    for version in versions
      if version.item_version_id
        # do nothing
      elsif version.event == "create"  
        version.item_version_id = 0
      else
        previous_id = 0
        previous_id = previous.item_version_id if previous && previous.item_version_id
        previous_id = 0 if previous &&
          ( version.item_type != previous.item_type || version.item_id != previous.item_id )
        records_merged = version.records_merged || 0
        version.item_version_id = previous_id + records_merged + 1
      end
      version.save!
      previous = version
    end
  end

  desc "Edit posts' past version.object to ensure version.reify.mod_status = version.mod_status"
  task edit_post_objects: :environment do
    versions = PaperTrail::Version.where("item_type = ? AND object IS NOT NULL", "Post")
    puts "DEBUG:"
    p versions.size
    for version in versions
      post = version.reify
      if post.mod_status != version.mod_status
        p post
        p version
        post.mod_status = version.mod_status
        version.object = post.serialize
        version.save!
        p version
      end
    end
  end

  desc "Copy post versions with current=true to new post_mods table."
  task copy_post_mods: :environment do
    versions = PaperTrail::Version.where("item_type = ? AND current = true", "Post").order(:created_at)
    puts "DEBUG:"
    p versions.size
    for version in versions
      puts "VERSION:"
      p version
      post                = version.reify
      p post
      post_mod            = PostMod.new
      post_mod.post       = post
      post_mod.author     = post.author
      post_mod.updater    = User.find(version.whodunnit)
      post_mod.visible    = post.visible
      post_mod.title      = post.title
      post_mod.slug       = post.slug
      post_mod.body       = post.body
      post_mod.main_image = post.main_image
      post_mod.channel    = post.channel
      post_mod.category   = post.category
      post_mod.mod_status = post.mod_status
      post_mod.created_at = post.created_at
      post_mod.updated_at = post.updated_at
      p post_mod
      post_mod.save!
    end
  end

end
