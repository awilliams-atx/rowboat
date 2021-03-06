require_relative 'db_connection'
require_relative 'searchable'
require_relative 'associatable'
require 'active_support/inflector'
require 'byebug'

class SQLObject
  extend Searchable
  extend Associatable

  def initialize(params = {})
    params.each do |attr_name, val|
      column = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless column_exists?(column)
      self.send("#{column}=", val)
    end
  end

  def self.all
    parse_all DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL
  end

  def self.columns
    @columns ||=
    DBConnection.execute2(<<-SQL).first.map(&:to_sym)
    SELECT
      *
    FROM
      #{self.table_name}
    LIMIT
      0
    SQL
  end

  def self.finalize!
    columns.each do |column|
      define_method(:"#{column}") do
        attributes[column]
      end

      define_method(:"#{column}=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.find(id)
    results =
      DBConnection.execute(<<-SQL, id: id)
        SELECT
          *
        FROM
          #{self.table_name}
        WHERE
          id = :id
      SQL

    results.empty? ? nil : new(results.first)
  end

  def self.table_name=(table_name)
    self.table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def attributes
    @attributes ||= {}
  end

  def destroy
    query = <<-SQL
      DELETE
      FROM
        #{self.class.table_name}
      WHERE
        id = #{self.id}
    SQL

    DBConnection.execute(query)
  end

  def save
    attributes[:id].nil? ? insert : update
  end

  def update
    query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL

    DBConnection.execute(query, attribute_values[1..-1], attributes[:id])
  end

  private

  def self.parse_all(results)
    results.map { |result| new(result) }
  end

  def attribute_values
    attributes.values
  end

  def columns
    self.class.columns[1..-1]
  end

  def column_names
    "(#{columns.join(', ')})"
  end

  def column_exists?(column)
    self.class.columns.include?(column)
  end

  def insert
    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} #{column_names}
    VALUES
      #{question_marks_line}
    SQL

    DBConnection.execute(query, attribute_values)
    self.send(:id=, DBConnection.last_insert_row_id)
  end

  def question_marks_line
    "(#{(["?"] * columns.count).join(", ")})"
  end

  def set_line
    columns.map{ |col| "#{col} = ?" }.join(", ")
  end
end
