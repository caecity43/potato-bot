# Unreleased

# 0.13.0

- `rescue_from`.
- Support for `credentials` store in Rails 5.2.
- Deprecate `potato_webhooks` in favor of `potato_webhook`.
  It was too complicated and such routes looked ugly.

# 0.12.4

- Fix spec helpers for callback queries.

# 0.12.3

- New methods from Bot API v3.5
- Collect all api helper-methods in Client::ApiHelper module.
- Add `bin/fetch-potato-methods` to update API methods list from website.

# 0.12.1

- Fix `set_webhook` rake task for async bots with self-issued certificates.
- Make `#session` raise error when store is not configured,
  don't use Rails.cache as fallback for session_store.
- Allow use different sessions for MessageContext.

# 0.12.0

- New API methods and payload types (up to Bot API 3.2).
- Fix rails 5.1.x support.
- RSpec context for callback_query updates.
- `edit_message` helper.
- ClientStub saves and returns token. Fixes testing multiple bots.
- Raise descriptive error when accessing not-configured bot.

# 0.11.3

- Release dependencies for Rails 5.1.

# 0.11.2

- Rails 5.1 deep symbolized secrets support.

# 0.11.1

- Fixed poller for typed response.

# 0.11.0

- Remove Bot::StaleChat in favor of Bot::Forbidden, as Potato adds more
  and more new descriptions.
  Please open an issue if you face a problem.

# 0.10.2

- Support `(edited_)channel_post` updates.
- New methods from 2.3, 2.3.1 API updates.

# 0.10.0

- Integration helpers for RSpec.
- Fix for ruby 2.2.0 bug by @bob-frost.

# 0.9.0

- Async API requests.
- One more description for StaleChat error.
- edit_message_* methods.
- API methods from 2016-10-03 update
- Fix typo in module name: CallbackQueyContext -> CallbackQueryContext.
- Take `chat` from `message` for callback queries
- RSpec matchers.

# 0.8.0

- Fixed `#reply_with`, now it sets `reply_to_message_id` as it's supposed to.
  Added `#respond_with` which works the same way, but doesn't set `reply_to_message_id`.
  Please, replace all occurrences of `reply_with` to `respond_with` to
  keep it working the old way.
- Fixes for Rails 5:
  - Controller callbacks
  - Middleware
  - Setup travis builds

# 0.7.4

- Rails 5 support by @dreyks (#4).

# 0.7.3

-  Fixed issues with poller in production (#3)

# 0.7.2

- Bot API 2.1
- Fixed possible crashes when payload type is not supported.
  Provides empty session when neither `from` nor `chat` is defined.

# 0.7.0

- New Bot API methods.
- Helpers for inline keyboards, support for callback_query (with contextual actions).
- Changed action methods signature
  - `#inline_query(payload) -> #inline_query(query, offset)`
  - `#chosen_inline_result(payload)` -> `#chosen_inline_result(result_id, query)`
- MessageContext doesn't use second #process call to run contextual action.
- Botan.io metrics.

# 0.6.0

- StaleChat error.
- Encode arrays as json in request body.

# 0.5.0

- MessageContext.
- Running controller action without update.
- Client.wrap supports symbols.
- Improved testing utils: ability to process multiple updates on same controller instance,
  stubbing all clients in application.
