require 'pry'
require 'pg'

HOSTNAME = :localhost
DATABASE = :tododb

class Todo
  attr_accessor :id, :task, :done

  def self.connect
    @@c = PGconn.new(host: HOSTNAME, dbname: DATABASE)
  end

  def self.close
    @@c.close
  end

  def self.create(args)
    todo = Todo.new(args)
    todo.save
  end

  def self.find(id)
    res = @@c.exec_params("SELECT * FROM todos WHERE id=$1", [id])
    throw "Record not found" unless res[0]
    Todo.new(res[0])
  end

  def self.update(id, task, done)
    puts "task: #{task}"
    puts "done: #{done}"
    puts "id: #{id}"
    res = @@c.exec_params("UPDATE todos SET task=$1, done=$2 WHERE id=$3", [task, done, id])
  end

  def self.all
    results = []
    res = @@c.exec "SELECT * FROM todos;"

    res.each do |todo|
      id = todo['id']
      task = todo['task']
      done = todo['done']

      results << Todo.new({id: id, task: task, done: done})
    end

    results
  end

  def initialize(args)
      @id = args[:id] if args.has_key? :id
      @task = args[:task] if args.has_key? :task
      @done = args[:done] if args.has_key? :done
      @id = args['id'] if args.has_key? 'id'
      @task = args['task'] if args.has_key? 'task'
      @done = args['done'] if args.has_key? 'done'
  end

  def save
    args = [task, done]
    if id.nil?
      sql = "INSERT INTO todos (task, done) VALUES ($1, $2)"
    else
      sql = "UPDATE todos SET task = $1, done = $2 WHERE id = $3"
      args.push id
    end

    sql += ' RETURNING *;'

    res = @@c.exec_params(sql, args)
    @id = res[0]['id']

    self
  end

  def self.delete(id)
    @@c.exec_params("DELETE FROM todos WHERE id=$1", [id])
  end

  def self.deleteAll
    @@c.exec_params("DELETE FROM todos")
  end

  def to_s
    if @done == 't'
      "#{@id}: #{@task} - done"
    else
      "#{@id}: #{@task}"
    end
  end
end


def userInterface
  def prompt
    puts '  Welcome to the todo app, what would you like to do?'
    puts 'n - make a new todo'
    puts 'l - list all todos'
    puts 'u [id] - update a todo with a given id'
    puts 'd [id] - delete a todo with a given id, if no id is provided, all todos will be deleted'
    puts 'q - quit the application'
    input = gets.chomp
    if input == 'n'
      self.make
    elsif input == 'l'
      self.list
    elsif input[0] == 'u'
      self.update(input.split(' ')[1])
    elsif input[0] == 'd'
      if input.split(' ').length == 1
        self.remove('A')
      elsif
        self.remove(input.split(' ')[1])
      end
    elsif input == 'q'
      self.quit
    else
      self.prompt
    end
  end

  def make
    print "TASK NAME: "
    task = gets.chomp
    print "DONE (t or f): "
    done = gets.chomp == 't'
    Todo.connect
    t = Todo.create({task: task, done: done})
    puts t
    Todo.close
    self.prompt
  end

  def update(id)
    Todo.connect
    t = Todo.find(id)
    puts t
    print "TASK NAME: "
    task = gets.chomp
    print "DONE (t or f): "
    done = gets.chomp == 't'
    Todo.update(id, task, done)
    Todo.close
    self.prompt
  end

  def remove(id)
    Todo.connect
    if id == 'A'
      Todo.deleteAll
    else
      Todo.delete(id)
    end
    Todo.close
    self.prompt
  end

  def list
    Todo.connect
    puts "**************************"
    puts Todo.all
    puts "**************************"
    Todo.close
    self.prompt
  end

  def quit
    puts "BYE!!!"
  end
end
userInterface.prompt
