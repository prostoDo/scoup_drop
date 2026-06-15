class SpaController < ActionController::API
  include ActionController::DataStreaming

  def index
    index_path = Rails.root.join("public/app/index.html")
    return head :not_found unless index_path.exist?

    send_file index_path, type: "text/html", disposition: "inline"
  end
end
