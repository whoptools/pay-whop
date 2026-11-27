# Releases

The latest published version is listed on [RubyGems](https://rubygems.org/gems/pay-whop).

1. Update the version constant and changelog in a pull request. Run `bin/test` and `bundle exec ruby bin/install-smoke`, and inspect the packaged files for credentials or private fixtures.
2. After review, merge approval and passing CI, create and push `vVERSION` from the intended clean `main` commit. The tag must match `Pay::Whop::VERSION`.
3. Watch the [Release workflow](https://github.com/whoptools/pay-whop/actions/workflows/release.yml). It runs CI, verifies that the tagged commit belongs to `main`, and publishes using RubyGems Trusted Publishing. No local RubyGems key or OTP is needed.
4. Verify the published version and its SHA-256 on RubyGems, install that exact artifact in the consumer app, and publish matching GitHub release notes.

If publishing fails, check whether RubyGems already accepted the version before retrying. Published versions cannot be overwritten; do not move an existing release tag.
