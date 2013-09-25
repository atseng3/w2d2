class Employee
  attr_accessor :name, :title, :salary, :boss

  def initialize(name, title, salary, boss)
    @name = name
    @title = title
    @salary = salary.to_i
    @boss = boss
  end

  def assign_manager(manager)
    @boss = manager
    manager.employees << self
  end

  def bonus(multiplier)
    bonus_amount = @salary * multiplier
  end
end

class Manager < Employee
  attr_accessor :employees

  def initialize(name, title, salary, boss, employees = [])
    super(name, title, salary, boss)
    @employees = employees
  end

  def bonus(multiplier)
    @employees.flatten.map! { |employee| employee.salary }.inject(:+) * multiplier
  end
end