defmodule Galaxy.AccountStatusView do
  use Galaxy.Web, :view

  def render("index.json", %{account_statuses: account_statuses}) do
    %{data: render_many(account_statuses, Galaxy.AccountStatusView, "account_status.json")}
  end

  def render("show.json", %{account_status: account_status}) do
    %{data: render_one(account_status, Galaxy.AccountStatusView, "account_status.json")}
  end

  def render("account_status.json", %{account_status: account_status}) do
    %{
      id: account_status.id,
      key: account_status.key,
      color: account_status.color,
      active: account_status.active,
    }
  end
end
