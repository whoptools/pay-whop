# Shared WhopTools navigation and fingerprinted stylesheet URLs. The kit in
# public/whoptools is vendored from whoptools/whoptools.com; see its README.
require "digest"

module WhopTools
  PUBLIC = Rails.root.join("public")
  HEADER = PUBLIC.join("whoptools/header.html").read.strip.html_safe
  FOOTER = PUBLIC.join("whoptools/footer.html").read.strip.html_safe
  # Repository links carry the GitHub mark and open the repository root.
  SOURCE_BUTTON = %(<a class="wt-button wt-button--surface" href="https://github.com/whoptools/pay-whop">#{PUBLIC.join("whoptools/github.svg").read.strip}Source code</a>).html_safe

  # Versioned URLs stop browsers pairing new markup with a cached old stylesheet.
  def self.asset_path(path)
    "/#{path}?v=#{Digest::SHA256.file(PUBLIC.join(path)).hexdigest[0, 10]}"
  end

  KIT_CSS = asset_path("whoptools/whoptools.css")
  FAVICON = asset_path("whoptools/favicon.svg")
  PLAYGROUND_CSS = asset_path("playground.css")
end
