require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
   self.to_s.downcase.pluralize
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end

  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = <<-SQL
      pragma table_info('#{table_name}')
    SQL

    table_info = DB[:conn].execute(sql)

    #column_names = []

    table_info.map do |row|
      row["name"] #column_names <<
    end.compact
    #column_names.compact
  end

  def save
      sql = <<-SQL
        INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
        VALUES (#{values_for_insert})
      SQL

      DB[:conn].execute(sql)

      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    # self.class.column_names is an array
    self.class.column_names.delete_if do |column_name|
      column_name == "id"
    end.join(", ")
  end

  def values_for_insert
    value_array = []

    self.class.column_names.each do |column|
      value_array << "'#{send(column)}'" unless send(column).nil?
    end

    value_array.join(", ")
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE name = ?
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(query_hash)
    #query_hash[key] = value
    key = query_hash.keys.first
    value = query_hash[key]

    sql = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE #{key} = ?
    SQL

    DB[:conn].execute(sql, value)
  end
end
