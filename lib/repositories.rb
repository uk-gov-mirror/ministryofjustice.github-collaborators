class Repository
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def id
    data.fetch("id")
  end

  def name
    data.fetch("name")
  end

  def locked?
    data.fetch("isLocked")
  end

  def archived?
    data.fetch("isArchived")
  end

  def disabled?
    data.fetch("isDisabled")
  end
end

class Repositories < GithubGraphQlClient
  attr_reader :login

  def initialize(params)
    @login = params.fetch(:login)
    super(params)
  end

  def list
    @list ||= get_all_repos
  end

  private

  def get_all_repos
    repos = []
    end_cursor = nil

    loop do
      data = get_repos(end_cursor)
      repos = repos + data.fetch("nodes").map { |d| Repository.new(d) }
      break unless data.dig("pageInfo", "hasNextPage")
      end_cursor = data.dig("pageInfo", "endCursor")
    end

    repos
  end

  def get_repos(end_cursor = nil)
    json = run_query(repositories_query(end_cursor))
    JSON.parse(json).dig("data", "organization", "repositories")
  end

  def repositories_query(end_cursor)
    after = end_cursor.nil? ? "" : %[, after: "#{end_cursor}"]
    %[
    {
      organization(login: "#{login}") {
        repositories(first: #{PAGE_SIZE} #{after}) {
          nodes {
            id
            name
            isLocked
            isArchived
            isDisabled
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
    ]
  end
end
