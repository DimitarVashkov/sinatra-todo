class TasksController < ApplicationController

  get '/tasks' do
    if logged_in?
      @tasks = Task.all
      erb :'tasks/index'
    else
      redirect '/login'
    end
  end

  get '/tasks/new' do
    if logged_in?
      erb :'tasks/new'
    else
      redirect '/login'
    end
  end

  get '/tasks/:id' do
    if logged_in?
      @task = Task.find_by_id(params[:id])
      erb :'tasks/show'
    else
      redirect '/login'
    end

  end

  post '/tasks' do
    if logged_in?
      task = current_user.tasks.build(title: params[:title], description: params[:description], due_date: params[:due_date])
      if task.save
        redirect "/tasks/#{task.id}"
      else
        redirect '/tasks/new'
      end
    else
      redirect '/login'
    end
  end

  get '/tasks/:id/edit' do
    if logged_in?
      @task = Task.find_by_id(params[:id])
      erb :'tasks/edit'
    else
      redirect '/login'
    end
  end

  patch '/tasks/:id' do
    if logged_in?
      @task = Task.find_by_id(params[:id])
      if @task && @task.user == current_user
        if @task.update(title: params[:title], description: params[:description], due_date: params[:due_date])
          redirect "/tasks/#{@task.id}"
        else
          redirect "/tasks/#{@task.id}/edit"
        end
      else
        redirect '/tasks'
      end
    else
      redirect to '/login'
    end

  end

  delete '/tasks/:id/delete' do
    if logged_in?
      @task = Task.find_by_id(params[:id])
      if @task && @task.user == current_user
        @task.delete
      end
      redirect to '/tasks'
    else
      redirect to '/login'
    end
  end

end
