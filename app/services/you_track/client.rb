require "net/http"
require "json"

module YouTrack
  class Client
    PAGE_SIZE = 100
    SPRINT_FIELDS = "id,name,start,finish,archived".freeze
    ISSUE_FIELDS = [
      "id",
      "idReadable",
      "summary",
      "customFields(name,$type,value(name,login,minutes,presentation,text))"
    ].join(",").freeze

    def initialize(
      base_url: ENV.fetch("YOUTRACK_BASE_URL"),
      token: ENV.fetch("YOUTRACK_API_TOKEN"),
      project_id: ENV.fetch("YOUTRACK_PROJECT_ID"),
      board_id: ENV.fetch("YOUTRACK_AGILE_BOARD_ID"),
      sprint_field_name: ENV.fetch("YOUTRACK_SPRINT_FIELD_NAME", "Sprint"),
      estimation_field_name: ENV.fetch("YOUTRACK_ESTIMATION_FIELD_NAME", "оценка BE")
    )
      @base_url = base_url.delete_suffix("/")
      @token = token
      @project_id = project_id
      @board_id = board_id
      @sprint_field_name = sprint_field_name
      @estimation_field_name = estimation_field_name
    end

    def sprints
      paginate("/api/agiles/#{escape(@board_id)}/sprints", fields: SPRINT_FIELDS)
    end

    def issues_for(sprint)
      query = "project: {#{@project_id}} #{@sprint_field_name}: {#{sprint.fetch("name")}}"
      paginate("/api/issues", fields: ISSUE_FIELDS, query: query).map { |issue| normalize_issue(issue) }
    end

    private

    def paginate(path, params)
      items = []
      skip = 0

      loop do
        page = get(path, params.merge("$top": PAGE_SIZE, "$skip": skip))
        raise Error, "Unexpected YouTrack response" unless page.is_a?(Array)

        items.concat(page)
        break if page.length < PAGE_SIZE

        skip += PAGE_SIZE
      end

      items
    end

    def get(path, params)
      uri = URI.join("#{@base_url}/", path.delete_prefix("/"))
      uri.query = URI.encode_www_form(params)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@token}"
      request["Accept"] = "application/json"

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 30
      ) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "YouTrack returned HTTP #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError, IOError, SystemCallError, Timeout::Error => error
      raise Error, error.message
    end

    def normalize_issue(raw)
      fields = Array(raw["customFields"])
      estimation = field_value(fields.find { |field| field["name"] == @estimation_field_name })
      assignee = field_value(fields.find { |field| user_field?(field) })
      status = field_value(fields.find { |field| state_field?(field) })
      key = raw.fetch("idReadable")

      {
        youtrack_id: raw.fetch("id"),
        key: key,
        summary: raw["summary"].presence || key,
        url: "#{@base_url}/issue/#{key}",
        assignee_name: value_name(assignee),
        status: value_name(status),
        estimation_be: decimal_value(estimation)
      }
    end

    def field_value(field)
      field && field["value"]
    end

    def user_field?(field)
      field["$type"].to_s.include?("UserIssueCustomField") ||
        field["name"].to_s.match?(/\A(assignee|исполнитель)\z/i)
    end

    def state_field?(field)
      field["$type"].to_s.include?("StateIssueCustomField") ||
        field["name"].to_s.match?(/\A(state|status|статус|состояние)\z/i)
    end

    def value_name(value)
      value.is_a?(Hash) ? (value["name"] || value["presentation"] || value["login"]) : value&.to_s
    end

    def decimal_value(value)
      raw = value.is_a?(Hash) ? (value["presentation"] || value["minutes"] || value["value"]) : value
      return if raw.nil? || raw == ""

      BigDecimal(raw.to_s.tr(",", "."))
    rescue ArgumentError
      nil
    end

    def escape(value)
      URI.encode_www_form_component(value)
    end
  end
end
