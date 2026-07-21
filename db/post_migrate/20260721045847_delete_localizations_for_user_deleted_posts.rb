# frozen_string_literal: true

class DeleteLocalizationsForUserDeletedPosts < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  BATCH_SIZE = 10_000

  def up
    loop do
      deleted_rows = DB.exec(<<~SQL, batch_size: BATCH_SIZE)
        WITH rows_to_delete AS (
          SELECT post_localizations.id
          FROM post_localizations
          INNER JOIN posts ON posts.id = post_localizations.post_id
          WHERE posts.user_deleted = true
          ORDER BY post_localizations.id
          LIMIT :batch_size
        )
        DELETE FROM post_localizations
        USING rows_to_delete
        WHERE post_localizations.id = rows_to_delete.id
      SQL

      break if deleted_rows == 0
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
