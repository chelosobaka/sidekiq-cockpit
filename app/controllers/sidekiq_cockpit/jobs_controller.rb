module SidekiqCockpit
  class JobsController < ApplicationController
    def index
      @group = params[:group].presence
      @failed_only = params[:failed] == '1'
      @overview = Queries::Overview.new.call(group: @group, failed_only: @failed_only)
    end

    def show
      @job = Queries::JobDetails.new.call(params[:name])
      raise ActionController::RoutingError, "Unknown job #{params[:name]}" unless @job
    end
  end
end
