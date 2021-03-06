class NotificationsController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    json = ActiveSupport::JSON.decode(request.body.read)
    Rails.logger.info json.inspect
    Rails.logger.error "Message Not Found" unless json["Message"]

    message = ActiveSupport::JSON.decode(json["Message"])
    process_notification_message(message)
    render nothing: true, status: :ok
  end

  private
  def process_notification_message(message)
    Rails.logger.error message["StatusMessage"] unless message["StatusCode"] == "Succeeded"
    case message["Action"]
    when "InventoryRetrieval"
      jid = message["JobId"]
      inventory_retrieval_job = InventoryRetrievalJob.find_by!(jid: jid)
      inventory_retrieval_job.archive_list.each(&:save)
    when "ArchiveRetrieval"
      jid = message["JobId"]
      aid = message["ArchiveId"]
      ArchiveDownloadWorker.perform_async(jid, aid)
    end
  end
end
