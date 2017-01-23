SecureHeaders::Configuration.default do |config|
  config.csp = {
    # directive values: these values will directly translate into source directives
    default_src: %w('self'),
    img_src: %w(* data:),
    script_src: %w(* 'unsafe-inline'),
    font_src: %w(*),
    style_src: %w(* 'unsafe-inline'),
    object_src: %w('self' create.extension.org),
    frame_src: %w(*)
  }
end
