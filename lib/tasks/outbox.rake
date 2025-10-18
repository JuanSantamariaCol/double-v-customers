namespace :outbox do
  desc "Publish pending outbox messages"
  task publish: :environment do
    puts "Publishing pending outbox messages..."

    pending_count = OutboxMessage.pending.count
    puts "Found #{pending_count} pending messages"

    if pending_count.zero?
      puts "No pending messages to publish"
      exit
    end

    OutboxPublisherJob.perform_now

    published = OutboxMessage.published.where("published_at > ?", 1.minute.ago).count
    failed = OutboxMessage.failed.where("updated_at > ?", 1.minute.ago).count

    puts "\nResults:"
    puts "  Published: #{published}"
    puts "  Failed: #{failed}"
    puts "\nDone!"
  end

  desc "Show outbox statistics"
  task stats: :environment do
    puts "\n=== Outbox Messages Statistics ==="
    puts "Total messages: #{OutboxMessage.count}"
    puts "Pending: #{OutboxMessage.pending.count}"
    puts "Published: #{OutboxMessage.published.count}"
    puts "Failed: #{OutboxMessage.failed.count}"

    puts "\n=== Recent Events (last 10) ==="
    OutboxMessage.order(created_at: :desc).limit(10).each do |msg|
      puts "  [#{msg.status.upcase}] #{msg.event_type} - #{msg.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    end

    if OutboxMessage.failed.any?
      puts "\n=== Failed Messages ==="
      OutboxMessage.failed.each do |msg|
        puts "  ID: #{msg.id} - #{msg.event_type}"
        puts "  Error: #{msg.error_message}"
        puts "  ---"
      end
    end
  end

  desc "Retry failed outbox messages"
  task retry_failed: :environment do
    failed_count = OutboxMessage.failed.count

    if failed_count.zero?
      puts "No failed messages to retry"
      exit
    end

    puts "Retrying #{failed_count} failed messages..."

    OutboxMessage.failed.update_all(status: "pending", error_message: nil)

    puts "All failed messages marked as pending"
    puts "Run 'rake outbox:publish' to publish them"
  end

  desc "Clean old published messages (older than 7 days)"
  task clean: :environment do
    cutoff_date = 7.days.ago
    count = OutboxMessage.published.where("published_at < ?", cutoff_date).count

    if count.zero?
      puts "No old published messages to clean"
      exit
    end

    puts "Deleting #{count} published messages older than 7 days..."
    OutboxMessage.published.where("published_at < ?", cutoff_date).delete_all
    puts "Done!"
  end
end
