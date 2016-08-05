defmodule Carbon.Account do
  use Carbon.Web, :model

  schema "accounts" do
    field :lock_version, :integer, default: 1
    field :name, :string
    field :active, :boolean, default: true

    belongs_to :owner, Carbon.User
    belongs_to :status, Carbon.AccountStatus
    belongs_to :billing_address, Carbon.Address
    belongs_to :shipping_address, Carbon.Address
    has_many :contacts, Carbon.Contact
    has_many :events, Carbon.Event
    has_many :deals, Carbon.Deal
    has_many :projects, Carbon.Project
    many_to_many :tags, Carbon.AccountTag, join_through: "j_accounts_tags"

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def create_changeset(account, params \\ %{}) do
    account
    |> cast(params, [:name, :status_id, :owner_id])
    |> cast_assoc(:contacts, required: true)
    |> validate_required(:name)
    |> validate_length(:name, min: 1)
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:status_id)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
