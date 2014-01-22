class TodoList
  attr_accessor :task_list
  include Enumerable
  def initialize list
    @task_list = list
  end
  def TodoList.parse text
    new text.split("\n").map { |row| Task.new(*row.split("|").map(&:strip)) }
  end
  def each
    @task_list.each { |task| yield task}
  end
  def filter criteria
    TodoList.new @task_list.select(&criteria.proc).compact
  end
  def adjoin other
    TodoList.new @task_list | other.task_list
  end
  def tasks_todo
    @task_list.count { |task| task.status == :todo }
  end
  def tasks_in_progress
    @task_list.count { |task| task.status == :current }
  end
  def tasks_completed
    @task_list.count { |task| task.status == :done }
  end
  def completed?
    @task_list.map { |task| task.status == :done }.all?
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
  attr_accessor :status, :description, :priority, :tags
  def initialize status, description, priority, tags=nil
    @status = status.downcase.to_sym
    @description = description
    @priority = priority.downcase.to_sym
    @tags = tags.to_s.split(',').map &:strip
  end
end