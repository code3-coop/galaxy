defmodule Carbon.AccountController do
  use Carbon.Web, :controller

  alias Carbon.Account

  def index(conn, params) do
    query = from a in Account,
      where: a.active == true,
      order_by: a.name,
      limit: ^min(Map.get(params, "limit", 25), 25),
      offset: ^Map.get(params, "offset", 0),
      left_join: c in assoc(a, :contacts),
      left_join: b in assoc(a, :billing_address),
      preload: [contacts: c, billing_address: b]
    render(conn, "index.html", accounts: Repo.all(query))
  end

  def new(conn, _params) do
    changeset = Account.changeset(%Account{contacts: [%Carbon.Contact{}]})
    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"account" => account_params}) do
    current_user = conn.assigns[:current_user]
    changeset = Account.create_changeset(%Account{owner: current_user}, account_params)

    case Repo.insert(changeset) do
      {:ok, account} ->
        conn
        |> put_flash(:info, "Account created successfully.")
        |> redirect(to: account_path(conn, :show, account.id))
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns[:current_user]

    query = from a in Account,
      where: a.id == ^id,
      join: s in assoc(a, :status),
      join: o in assoc(a, :owner),
      left_join: ba in assoc(a, :billing_address),
      left_join: sa in assoc(a, :shipping_address),
      left_join: e in Carbon.Event, on: e.account_id == a.id and ago(1, "year") <= e.date and e.date <= from_now(1, "year"),
      left_join: eu in assoc(e, :user),
      left_join: er in Carbon.Reminder, on: er.event_id == e.id and er.user_id == ^current_user.id,
      left_join: et in assoc(e, :tags),
      left_join: d in assoc(a, :deals),
      left_join: dt in assoc(d, :tags),
      left_join: c in assoc(a, :contacts),
      left_join: ct in assoc(c, :tags),
      left_join: t in assoc(a, :tags),
      preload: [
        status: s,
        owner: o,
        billing_address: ba,
        shipping_address: sa,
        events: {e, user: eu, reminders: er, tags: et},
        deals: {d, tags: dt},
        contacts: {c, tags: ct},
        tags: t
      ]
    account = Repo.one(query)
    render(conn, "show.html", account: account)
  end

  def edit(conn, %{"id" => id}) do
    account_query = from a in Account,
      where: a.id == ^id,
      join: s in assoc(a, :status),
      join: o in assoc(a, :owner),
      left_join: ba in assoc(a, :billing_address),
      left_join: sa in assoc(a, :shipping_address),
      left_join: t in assoc(a, :tags),
      preload: [
        status: s,
        owner: o,
        billing_address: ba,
        shipping_address: sa,
        tags: t
      ]
    account = Repo.one(account_query)
    changeset = Account.changeset(account)

    render(conn, "edit.html", account: account, changeset: changeset)
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    tags = get_account_tags_from(account_params)
    account = Repo.get!(Account, id) |> Repo.preload([:status, :owner, :billing_address, :shipping_address, :tags])
    changeset = Account.update_changeset(account, account_params, tags)

    case Repo.update(changeset) do
      {:ok, account} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: account_path(conn, :show, account))
      {:error, changeset} ->
        render(conn, "edit.html", account: account, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Repo.get!(Account, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(account)

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: account_path(conn, :index))
  end

  def event_list(_conn, %{"id" => _id}) do
  end

  defp get_account_tags_from(%{"tags_id" => ""}), do: []
  defp get_account_tags_from(%{"tags_id" => tags_id_param}) do
    ids = tags_id_param |> String.split(~r{\s*,\s*}) |> Enum.map(&String.to_integer/1)
    Repo.all(from t in Carbon.AccountTag, where: t.id in ^ids)
  end

end
