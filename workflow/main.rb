require 'sqlite3'
require_relative 'lib/alfred-workflow-ruby/alfred-3_workflow'

module AlfredPostico
  class Browse
    attr_reader :workflow, :connections

    def initialize
      db_path = "#{ENV['HOME']}/Library/Containers/at.eggerapps.Postico/Data/Library/Application Support/Postico/ConnectionFavorites.db"
      db = SQLite3::Database.new(db_path)
      db.results_as_hash = true

      @workflow = Alfred3::Workflow.new
      @connections = db.execute <<~SQL
        SELECT ZUSER, ZPORT, ZDATABASE, ZNICKNAME, ZUUID
        FROM ZPGEFAVORITE
      SQL
    end

    def open
      connections.empty? ? empty_json : output_json
      print workflow.output
    end

    def build_connection_string(connection)
      user = "#{connection['ZUSER']}@" unless connection['ZUSER'].nil?
      host = connection['ZHOST'] || 'localhost'
      port = ":#{connection['ZPORT']}" unless connection['ZPORT'].nil?
      db   = connection['ZDATABASE']

      "postgresql://#{user}#{host}#{port}/#{db}"
    end

    def output_json
      connections.each do |connection|
        database_name = connection['ZDATABASE']
        next if database_name.nil?

        connection_name = connection['ZNICKNAME']
        uuid = connection['ZUUID']
        connection_string = build_connection_string(connection)

        workflow.result
                .uid(uuid)
                .title(connection_name)
                .subtitle(database_name)
                .arg(connection_string)
                .text('copy', connection_string)
                .autocomplete(connection_name)
      end
    end

    def empty_json
      workflow.result
              .title('No database connections available!')
              .subtitle('Open Postico to add a database connection')
              .arg('-a Postico')
    end
  end
end

AlfredPostico::Browse.new.open
