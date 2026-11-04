class ReportJob < ActiveJob::Base
  queue_as :reports

  def perform(_period); end
end
