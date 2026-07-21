# frozen_string_literal: true

require Rails.root.join(
          "db/post_migrate/20260721045847_delete_localizations_for_user_deleted_posts.rb",
        )

describe DeleteLocalizationsForUserDeletedPosts do
  before do
    @original_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
  end

  after { ActiveRecord::Migration.verbose = @original_verbose }

  it "deletes localizations for user-deleted posts" do
    user_deleted_post = Fabricate(:post, user_deleted: true)
    stale_localization = Fabricate(:post_localization, post: user_deleted_post)

    described_class.new.up

    expect(PostLocalization.exists?(stale_localization.id)).to eq(false)
  end

  it "preserves localizations for posts that were not deleted by their author" do
    regular_post = Fabricate(:post)
    moderator_deleted_post = Fabricate(:post, deleted_at: 1.day.ago, user_deleted: false)
    regular_localization = Fabricate(:post_localization, post: regular_post)
    moderator_deleted_localization = Fabricate(:post_localization, post: moderator_deleted_post)

    described_class.new.up

    expect(
      PostLocalization.where(
        id: [regular_localization.id, moderator_deleted_localization.id],
      ).pluck(:id),
    ).to contain_exactly(regular_localization.id, moderator_deleted_localization.id)
  end
end
