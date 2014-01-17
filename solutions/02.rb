module Parser
  def self.format(list)
    list.map do |item|
      item[0] = item[0].downcase.to_sym
      item[2] = item[2].downcase.to_sym
      item[3] = item[3].gsub(/, +/, ',').strip.split(",")
    end
  end

  def self.create_tasks(list)
    format(list)
    tasks = []
    1.upto(list.length).each { tasks << Task.new }
    tasks.each_with_index { |item, index| item.task = list[index] }
  end
end

module Filter
  def filter(norm, filtered = [])
    @list.each_with_object(norm.first) do |task, crit|
      filtered << Filter.filtered_task(task, crit)
    end
    filtered = TodoList.new(filtered.uniq.compact)
  end

  def self.filtered_task(task, crit)
    if Filter.contains? task.task, crit
      task
    end
  end

  def self.contains?(task, other)
    return task.flatten.include? other if not other.kind_of? Array
    return true if other.empty?
    return contains? task, other.drop(1) if contains? task, other.first
    false
  end
end

module Statistics
  def tasks_todo
    reduce(0) { |memo, item| memo += item.count(:todo) }
  end

  def tasks_in_progress
    reduce(0) { |memo, item| memo += item.count(:current) }
  end

  def tasks_completed
    reduce(0) { |memo, item| memo += item.count(:done) }
  end

  def completed?
    completed = true
    each { |item| completed = item.task[0] == :done }
    completed
  end
end

class TodoList
  include Enumerable
  include Filter
  include Statistics
  attr_accessor :list

  def initialize(value = [])
    @list = value
  end

  def each
    @list.each { |item| yield item }
  end

  def self.parse(text)
    list = []
    text.each_line { |line| list << line.gsub(/[ ]*[|][ ]*/, '|').split("|") }
    TodoList.new(Parser.create_tasks(list))
  end

  def adjoin(other)
    TodoList.new((@list + other.list).uniq { |item| item.task[1] })
  end
end

class Criteria
  include Enumerable
  attr_accessor :criteria

  def initialize(value)
    @criteria = value
  end

  def self.status(value)
    Criteria.new([value]) if [:todo, :current, :done].include? value
  end

  def self.priority(value)
    Criteria.new([value]) if [:low, :normal, :high].include? value
  end

  def self.tags(value)
    Criteria.new([value])
  end

  def |(other)
    Criteria.new([@criteria] + [other.criteria])
  end

  def &(other)
    Criteria.new([@criteria + other.criteria])
  end

  def !
    if Filter.contains? [:todo, :current, :done], @criteria
      return Criteria.new(([:todo, :current, :done] - @criteria).product)
    end
    if Filter.contains? [:low, :normal, :high], @criteria
      return Criteria.new(([:low, :normal, :high] - @criteria).product)
    end
  end

  def each
    @criteria.each { |item| yield item }
  end
end

class Task
  include Enumerable
  attr_accessor :task

  def each
    @task.each { |item| yield item }
  end

  def status
    task[0]
  end

  def description
    task[1]
  end

  def priority
    task[2]
  end

  def tags
    task[3]
  end
end