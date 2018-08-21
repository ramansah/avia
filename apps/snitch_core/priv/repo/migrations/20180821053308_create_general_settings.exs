defmodule Snitch.Repo.Migrations.CreateGeneralSettings do
  use Ecto.Migration

  def change do
    create table("snitch_general_settings") do
      add(:site_name, :string)
      add(:seo_title, :string)
      add(:meta_keywords, :string)
      add(:meta_description, :string)
      add(:mail_from, :string)

      timestamps()
    end
  end
end
