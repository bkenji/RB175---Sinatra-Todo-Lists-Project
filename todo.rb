# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'ffb0ae7a3db963272cc584ec05b3afee945aca81f98972151b162c4cccea32e8'
  set :erb, :escape_html => true
end

helpers do
  def list_completed?(list)
    todos_count(list).positive? &&
      all_checked?(list[:todos])
  end

  def todo_class(todo)
    'complete' if todo[:completed]
  end

  def all_checked?(todos)
    todos.all? { |todo| todo[:completed] }
  end

  def todos_count(list)
    list[:todos].size
  end

  def remaining_todos_count(list)
    list[:todos].count { |todo| todo[:completed] == false }
  end

  # def sort_list!(list) # original solution
  #   list.sort_by! { |todo| todo[:completed] ? 1 : 0 }
  # end

  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end

  # def sort_lists(lists) # original solution
  #   lists.sort_by! { |list| list_completed?(list) ? 1 : 0 }
  # end

  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
  # @list_number = params[:list_number].to_i
end

# Root
get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @todos = session[:lists]
  erb :lists, layout: :layout
end

# Alternative route format
get '/lists/' do
  redirect '/lists'
end

# Render new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return error message if list name is invalid, else returns nil.
def list_name_error
  if !(1..100).cover? @list_name.size
    'Name must be between 1 and 100 characters.'
  elsif @lists.any? { |list| list[:name] == @list_name }
    'Name already exists.'
  end
end

# Create a new list
post '/lists' do
  @list_name = params[:list_name].strip

  if list_name_error
    session[:error] = list_name_error
    erb :new_list, layout: :layout
  else
    @lists << { name: @list_name, todos: [] }
    session[:success] = 'List created successfully.'
    redirect '/lists'
  end
end

# Retrieve individual lists
get '/lists/:list_number' do
  @list_number = params[:list_number].to_i
  @list = @lists[@list_number]
  @todos = @list[:todos]

  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:list_number/edit' do
  @list_number = params[:list_number].to_i
  @list = @lists[@list_number]
  erb :edit_list, layout: :layout
end

# Update existing todo list
post '/lists/:list_number' do
  @list_name = params[:new_list_name].strip
  @list_number = params[:list_number].to_i
  @list = @lists[@list_number]

  if list_name_error
    session[:error] = list_name_error
    erb :edit_list, layout: :layout
  else
    @list[:name] = @list_name
    session[:success] = 'List name has been updated.'
    redirect "/lists/#{@list_number}"
  end
end

# Delete a todo list
post '/lists/:list_number/delete' do
  @list_number = params[:list_number]
  session[:success] = "\"#{@lists[@list_number.to_i][:name]}\" has been deleted."
  @lists.delete_at(@list_number.to_i)
  redirect '/lists'
end

# Error handling for todo editing
def todo_name_error
  return if (1..100).cover? @todo_name.size

  'Name must be between 1 and 100 characters.'
end

# Add new todo to list
post '/lists/:list_number/todos' do
  @list_number = params[:list_number].to_i
  @todo_name = params[:todo].strip
  @todos = @lists[@list_number][:todos]
  @list = @lists[@list_number]

  if todo_name_error
    session[:error] = todo_name_error
    erb :list, layout: :layout
  else
    @todos << { name: params[:todo], completed: false }
    session[:success] = 'Todo item was successfully added.'
    redirect "/lists/#{@list_number}"
  end
end

# Delete todo item from individual list
post '/lists/:list_number/todos/:todo_number/delete' do
  @list_number = params[:list_number].to_i
  @list = @lists[@list_number]
  @todos = @list[:todos]
  @todo_index = params[:todo_number].to_i

  if @todos[@todo_index].nil? || @todos[@todo_index][:name] != params[:todo_name]
    session[:error] = 'The todo item does not exist or has already been removed. Showing updated list.'
    erb :list, layout: :layout
  else
    session[:success] = "'#{@todos[@todo_index][:name]}' todo item was successfully deleted."
    @todos.delete_at(@todo_index)
    redirect "/lists/#{@list_number}"
  end
end

def completed?
  @todo[:completed] ? 'completed' : 'not yet completed'
end

# Update status of a todo
post '/lists/:list_number/todos/:todo_number' do
  @list_number = params[:list_number].to_i
  @list = @lists[@list_number]
  @todos = @list[:todos]
  @todo_index = params[:todo_number].to_i
  @todo = @todos[@todo_index]

  @todo[:completed] = params[:completed] == 'true'
  session[:success] = "\"#{@todo[:name]}\" has been marked as #{completed?}."
  redirect "lists/#{@list_number}"
end

# Check all todos as complete for a list
post '/lists/:list_number/todo_all' do
  @list_number = params[:list_number].to_i
  @list = @lists[@list_number]
  @todos = @list[:todos]

  @todos.each { |todo| todo[:completed] = true }
  session[:success] = 'All todos have been updated.'

  redirect "lists/#{@list_number}"
end

get '/logout' do
  session.clear
  redirect '/lists'
end
