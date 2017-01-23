SecureHeaders::Configuration.default do |config|
  config.csp = {
    # directive values: these values will directly translate into source directives
    default_src: %w('self'),
    img_src: %w(* data:),
    script_src: %w('self', 'unsafe-inline', *.extension.org),
    style_src: %w('self' fonts.googleapis.com),
    object_src: %w('self', create.extension.org)
  }
end
