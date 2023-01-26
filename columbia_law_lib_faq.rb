require 'csv'
require 'dotenv/load'
require 'erubis'
require 'google_drive'
require 'sinatra'

# Retrieve environment variables in development
Dotenv.load if settings.development?

# Automatically escape all HTML content
set :erb, escape_html: true

# Root path displays search results
get '/' do
  @query = params[:query]

  if @query.nil?
    @title = 'FAQs | Columbia Law Library'
  else
    @title = "Results for '#{@query}'"
    @matches = search_database(@query)
  end

  erb :search
end

# List of all FAQs grouped by topics
get '/list' do
  @title = 'FAQs | Columbia Law Library'
  @database = grouped_database_by_topic

  erb :list
end

# Redirect to root when a page cannot be found
not_found do
  redirect '/'
end

# Exceed Google API limit
error 500 do
  @query = params[:query]
  erb :oops
end

# rubocop:disable Metrics/BlockLength
helpers do
  # Yields question, answer, and topic from each entry in a CSV table
  def each_entry(database)
    database.each { |row| yield row['Question'], row['Answer'], row['Topic'] }
  end

  # Returns a CSV table from the first worksheet of the Google spreadsheet
  def get_database
    session = GoogleDrive::Session.from_service_account_key('service_account_key.json')
    spreadsheet = session.spreadsheet_by_url(ENV.fetch('DATABASE_URL'))
    worksheet = spreadsheet.worksheets.first
    CSV.parse(worksheet.export_as_string, headers: true)
  end

  # Returns an array of hashes, each hash has a question key and an answer key
  def search_database(query)
    matches = []
    return matches unless query&.length&.positive?

    each_entry(get_database) do |question, answer, _|
      matches << { question:, answer: } if (question =~ /#{query}/i) || (answer =~ /#{query}/i)
    end

    matches
  end

  # Returns a hash e.g. { "Collection" => [{question: "qn", answer: "ans"}]}
  # The keys are the topic names, and the values are arrays of simple hashes
  def grouped_database_by_topic
    grouped_database = Hash.new { |hash, key| hash[key] = [] }

    each_entry(get_database) do |question, answer, topic|
      grouped_database[topic] << { question:, answer: }
    end

    grouped_database
  end
end
# rubocop:enable Metrics/BlockLength

# Ensure that the page loads as an iframe widget
after do
  headers({
            'Content-Security-Policy' => 'frame-ancestors https://law-columbia.libapps.com https://guides.law.columbia.edu/'
          })
end
