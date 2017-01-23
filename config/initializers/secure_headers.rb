SecureHeaders::Configuration.default do |config|
  config.csp = {
    # directive values: these values will directly translate into source directives
    default_src: %w('self'),
    img_src: %w(* data:),
    script_src: %w(* 'self' 'unsafe-inline'),
    font_src: %w('self' fonts.gstatic.com),
    style_src: %w('self' fonts.googleapis.com 'unsafe-inline'),
    object_src: %w('self' create.extension.org)
  }
end
