module Api
  class BaseController < ApplicationController
    before_action :require_authenticated!
  end
end
