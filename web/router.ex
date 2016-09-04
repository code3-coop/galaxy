defmodule Carbon.Router do
  use Carbon.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug Carbon.SessionPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Carbon do
    pipe_through [:browser, :auth]

    get "/", PageController, :index

    put "/timesheets/:id/restore", TimesheetController, :restore
    resources "/timesheets", TimesheetController do
      resources "/entries", TimesheetEntryController
      put "/entries/:id/restore", TimesheetEntryController, :restore
    end

    put "/accounts/:id/restore", AccountController, :restore

    resources "/accounts", AccountController do
      resources "/contacts", ContactController, except: [:index, :show]
      put "/contacts/:id/restore", ContactController, :restore

      get "/activities", ActivityController, :index

      resources "/deals", DealController
      put "/deals/:id/restore", DealController, :restore

      resources "/events", EventController do
        post   "/reminders", ReminderController, :create
        get    "/reminders/new", ReminderController, :new
        delete "/reminders/:id", ReminderController, :delete
        put    "/reminders/:id", ReminderController, :restore
      end
      put "/events/:id/restore", EventController, :restore

      resources "/attachments", AttachmentController
    end

    resources "/tags", TagController, except: [:show]
    put "/tags/:id/restore", TagController, :restore

    resources "/users", UserController



    resources "/workflows/instances", Workflow.InstanceController, except: [:show]
    put "/workflows/instances/:id/restore", Workflow.InstanceController, :restore
    get "/workflows/instances/:ids/process", Workflow.InstanceController, :process

    resources "workflows", Workflow.WorkflowController

  end

  scope "/session", Carbon do
    pipe_through :browser

    get "/", SessionController, :index
    post "/", SessionController, :create_and_send_session_link
    get "/validate/:token", SessionController, :validate_token
    get "/logout", SessionController, :logout
  end

  scope "/api", Carbon do
    pipe_through :api
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.EmailPreviewPlug
  end
end
