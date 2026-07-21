# frozen_string_literal: true

module Jobs
  class RebakeGithubPrPosts < ::Jobs::Base
    sidekiq_options queue: "low"

    def execute(args)
      url = args[:pr_url]
      return if url.blank?

      rebake_posts(url)
      rebake_chat_messages(url) if SiteSetting.chat_enabled
    end

    private

    # anchored so /pull/12 does not match /pull/123
    def pr_links(relation, url)
      escaped = ActiveRecord::Base.sanitize_sql_like(url)
      relation.where(
        "url = :url OR url LIKE :path OR url LIKE :query OR url LIKE :fragment",
        url:,
        path: "#{escaped}/%",
        query: "#{escaped}?%",
        fragment: "#{escaped}#%",
      )
    end

    # oneboxes are cached per exact URL, which may differ from the webhook's canonical URL
    def invalidate_onebox_caches(urls)
      urls.each do |url|
        Oneboxer.invalidate(url)
        InlineOneboxer.invalidate(url)
      end
    end

    def rebake_posts(url)
      links = pr_links(TopicLink, url)
      invalidate_onebox_caches(links.distinct.pluck(:url))

      Post
        .where(id: links.select(:post_id))
        .where(
          "cooked LIKE :pattern AND (cooked LIKE '%githubpullrequest%' OR cooked LIKE '%inline-onebox%')",
          pattern: "%#{ActiveRecord::Base.sanitize_sql_like(url)}%",
        )
        .find_each { |post| post.rebake!(priority: :low, skip_publish_rebaked_changes: true) }
    end

    def rebake_chat_messages(url)
      links = pr_links(::Chat::MessageLink, url)
      invalidate_onebox_caches(links.distinct.pluck(:url))

      ::Chat::Message
        .where(id: links.select(:chat_message_id))
        .where(
          "cooked LIKE :pattern AND (cooked LIKE '%githubpullrequest%' OR cooked LIKE '%inline-onebox%')",
          pattern: "%#{ActiveRecord::Base.sanitize_sql_like(url)}%",
        )
        .find_each { |message| message.rebake!(priority: :low, skip_notifications: true) }
    end
  end
end
