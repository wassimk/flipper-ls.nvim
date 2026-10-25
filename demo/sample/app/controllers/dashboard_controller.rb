# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    @projects = current_user.projects
    @analytics = AnalyticsService.fetch(current_user.team)
  end
end
