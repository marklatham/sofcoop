namespace :filenames do
  
  desc "Update S3 filenames overnight, in case a username changed"
  task update: :environment do
    start_time = Time.now
    mismatches = 0
    log_report = []
    log_report << "Start time = " + start_time.inspect
    s3_client = Fog::Storage::AWS.new(aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                  aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
                                                 region: 'us-west-2')
    puts "Bucket: " + ENV['AWS_S3_BUCKET']
    # bucket is synonym for directory
    bucket = s3_client.directories.get(ENV['AWS_S3_BUCKET'],
                                       options = {region: 'us-west-2'})
    puts "Bucket Region: " + bucket.location.to_s
    images = Image.all
    for image in images
      aws_filename = image.file_url.partition('?').first.partition('/images/').last
      sofcoop_filename = image.user.username + '/' + image.slug + '.' + image.format
      unless aws_filename == sofcoop_filename
        mismatches += 1
        log_report << "AWS: " + aws_filename
        log_report << "=>SC: " + sofcoop_filename
        image.remote_file_url = image.file_url
        image.save!
      end
    end
    log_report << "Number of filename mismatches = " + mismatches.to_s
    finish_time = Time.now
    log_report << "Total time = " + (finish_time - start_time).round.to_s + " seconds"
    log_report << "so about " + ((finish_time - start_time)/mismatches).round.to_s +
                  " seconds per mismatch" if mismatches > 0
    AdminMailer.filenames_update(log_report).deliver
  end
  
end
