require 'spec_helper'

describe ApplicationController do

  describe "Homepage" do
    it 'loads the homepage' do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Welcome to Todos")
    end
  end

  describe "Signup Page" do

    it 'loads the signup page' do
      get '/signup'
      expect(last_response.status).to eq(200)
    end

    it 'signup directs user to twitter index' do
      params = {
        :username => "skittles123",
        :email => "skittles@aol.com",
        :password => "rainbows"
      }
      post '/signup', params
      expect(last_response.location).to include("/tasks")
    end

    it 'does not let a user sign up without a username' do
      params = {
        :username => "",
        :email => "skittles@aol.com",
        :password => "rainbows"
      }
      post '/signup', params
      expect(last_response.location).to include('/signup')
    end

    it 'does not let a user sign up without an email' do
      params = {
        :username => "skittles123",
        :email => "",
        :password => "rainbows"
      }
      post '/signup', params
      expect(last_response.location).to include('/signup')
    end

    it 'does not let a user sign up without a password' do
      params = {
        :username => "skittles123",
        :email => "skittles@aol.com",
        :password => ""
      }
      post '/signup', params
      expect(last_response.location).to include('/signup')
    end

    it 'does not let a logged in user view the signup page' do
      user = User.create(:username => "skittles123", :email => "skittles@aol.com", :password => "rainbows")
      params = {
        :username => "skittles123",
        :email => "skittles@aol.com",
        :password => "rainbows"
      }
      post '/signup', params
      session = {}
      session[:user_id] = user.id
      get '/signup'
      expect(last_response.location).to include('/tasks')
    end
  end

  describe "login" do
    it 'loads the login page' do
      get '/login'
      expect(last_response.status).to eq(200)
    end

    it 'loads the tasks index after login' do
      user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
      params = {
        :username => "becky567",
        :password => "kittens"
      }
      post '/login', params
      expect(last_response.status).to eq(302)
      follow_redirect!
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("Todos")
    end

    it 'does not let user view login page if already logged in' do
      user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")

      params = {
        :username => "becky567",
        :password => "kittens"
      }
      post '/login', params
      session = {}
      session[:user_id] = user.id
      get '/login'
      expect(last_response.location).to include("/tasks")
    end
  end

  describe "logout" do
    it "lets a user logout if they are already logged in" do
      user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")

      params = {
        :username => "becky567",
        :password => "kittens"
      }
      post '/login', params
      get '/logout'
      expect(last_response.location).to include("/login")
    end

    it 'does not let a user logout if not logged in' do
      get '/logout'
      expect(last_response.location).to include("/")
    end

    it 'does not load /tasks if user not logged in' do
      get '/tasks'
      expect(last_response.location).to include("/login")
    end

    it 'does load /tasks if user is logged in' do
      user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")


      visit '/login'

      fill_in(:username, :with => "becky567")
      fill_in(:password, :with => "kittens")
      click_button 'submit'
      expect(page.current_path).to eq('/tasks')
    end
  end

  describe 'user show page' do
    it 'shows all a single users tasks' do
      user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
      task1 = Task.create(:title => "tasking!", :description => 'Hello', :user_id => user.id)
      task2 = Task.create(:title => "task task task", :description => 'Hello', :user_id => user.id)

      get "/users/#{user.slug}"

      expect(last_response.body).to include("tasking!")
      expect(last_response.body).to include("task task task")

    end
  end

  describe 'index action' do
    context 'logged in' do
      it 'lets a user view the tasks index if logged in' do
        user1 = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task1 = Task.create(:title => "tasking!", :description => 'Hello', :user_id => user1.id)

        user2 = User.create(:username => "silverstallion", :email => "silver@aol.com", :password => "horses")
        task2 = Task.create(:title => "look at this task", :description => 'Hello', :user_id => user2.id)

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit "/tasks"
        expect(page.body).to include(task1.title)
        expect(page.body).to include(task2.title)
      end
    end

    context 'logged out' do
      it 'does not let a user view the tasks index if not logged in' do
        get '/tasks'
        expect(last_response.location).to include("/login")
      end
    end
  end

  describe 'new action' do
    context 'logged in' do
      it 'lets user view new task form if logged in' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit '/tasks/new'
        expect(page.status_code).to eq(200)
      end

      it 'lets user create a task if they are logged in' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'

        visit '/tasks/new'
        fill_in(:title, :with => "task!!!")
        click_button 'submit'

        user = User.find_by(:username => "becky567")
        task = Task.find_by(:title => "task!!!")
        expect(task).to be_instance_of(Task)
        expect(task.user_id).to eq(user.id)
        expect(page.status_code).to eq(200)
      end

      it 'does not let a user task from another user' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        user2 = User.create(:username => "silverstallion", :email => "silver@aol.com", :password => "horses")

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'

        visit '/tasks/new'

        fill_in(:title, :with => "task!!!")
        click_button 'submit'

        user = User.find_by(:id=> user.id)
        user2 = User.find_by(:id => user2.id)
        task = Task.find_by(:title => "task!!!")
        expect(task).to be_instance_of(Task)
        expect(task.user_id).to eq(user.id)
        expect(task.user_id).not_to eq(user2.id)
      end

      it 'does not let a user create a blank task' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'

        visit '/tasks/new'

        fill_in(:title, :with => "")
        click_button 'submit'

        expect(Task.find_by(:title => "")).to eq(nil)
        expect(page.current_path).to eq("/tasks/new")
      end
    end

    context 'logged out' do
      it 'does not let user view new task form if not logged in' do
        get '/tasks/new'
        expect(last_response.location).to include("/login")
      end
    end
  end

  describe 'show action' do
    context 'logged in' do
      it 'displays a single task' do

        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task = Task.create(:title => "i am a boss at tasking", :user_id => user.id)

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'

        visit "/tasks/#{task.id}"
        expect(page.status_code).to eq(200)
        expect(page.body).to include("Delete Task")
        expect(page.body).to include(task.title)
        expect(page.body).to include("Edit Task")
      end
    end

    context 'logged out' do
      it 'does not let a user view a task' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task = Task.create(:title => "i am a boss at tasking", :user_id => user.id)
        get "/tasks/#{task.id}"
        expect(last_response.location).to include("/login")
      end
    end
  end

  describe 'edit action' do
    context "logged in" do
      it 'lets a user view task edit form if they are logged in' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task = Task.create(:title => "tasking!", :user_id => user.id)
        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit '/tasks/1/edit'
        expect(page.status_code).to eq(200)
        expect(page.body).to include(task.title)
      end

      it 'does not let a user edit a task they did not create' do
        user1 = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task1 = Task.create(:title => "tasking!", :user_id => user1.id)

        user2 = User.create(:username => "silverstallion", :email => "silver@aol.com", :password => "horses")
        task2 = Task.create(:title => "look at this task", :user_id => user2.id)

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        session = {}
        session[:user_id] = user1.id
        visit "/tasks/#{task2.id}/edit"
        expect(page.current_path).to include('/tasks')
      end

      it 'lets a user edit their own task if they are logged in' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task = Task.create(:title => "tasking!", :user_id => 1)
        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit '/tasks/1/edit'

        fill_in(:title, :with => "i love tasking")

        click_button 'submit'
        expect(Task.find_by(:title => "i love tasking")).to be_instance_of(Task)
        expect(Task.find_by(:title => "tasking!")).to eq(nil)
        expect(page.status_code).to eq(200)
      end

      it 'does not let a user edit a text with blank title' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task = Task.create(:title => "tasking!", :user_id => 1)
        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit '/tasks/1/edit'

        fill_in(:title, :with => "")

        click_button 'submit'
        expect(Task.find_by(:title => "i love tasking")).to be(nil)
        expect(page.current_path).to eq("/tasks/1/edit")
      end
    end

    context "logged out" do
      it 'does not load -- instead redirects to login' do
        get '/tasks/1/edit'
        expect(last_response.location).to include("/login")
      end
    end
  end

  describe 'delete action' do
    context "logged in" do
      it 'lets a user delete their own task if they are logged in' do
        user = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task = Task.create(:title => "tasking!", :user_id => 1)
        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit 'tasks/1'
        click_button "Delete Task"
        expect(page.status_code).to eq(200)
        expect(Task.find_by(:title => "tasking!")).to eq(nil)
      end

      it 'does not let a user delete a task they did not create' do
        user1 = User.create(:username => "becky567", :email => "starz@aol.com", :password => "kittens")
        task1 = Task.create(:title => "tasking!", :user_id => user1.id)

        user2 = User.create(:username => "silverstallion", :email => "silver@aol.com", :password => "horses")
        task2 = Task.create(:title => "look at this task", :user_id => user2.id)

        visit '/login'

        fill_in(:username, :with => "becky567")
        fill_in(:password, :with => "kittens")
        click_button 'submit'
        visit "tasks/#{task2.id}"
        click_button "Delete Task"
        expect(page.status_code).to eq(200)
        expect(Task.find_by(:title => "look at this task")).to be_instance_of(Task)
        expect(page.current_path).to include('/tasks')
      end
    end

    context "logged out" do
      it 'does not load let user delete a task if not logged in' do
        task = Task.create(:title => "tasking!", :user_id => 1)
        visit '/tasks/1'
        expect(page.current_path).to eq("/login")
      end
    end
  end
end
