class RedirectRoutingController < ActionController::Base
  def redirect
    options = params[:args].extract_options!
    options.delete(:conditions)
    status = options.delete(:permanent) == true ? :moved_permanently : :found
    url_options = params[:args].first || options
    # jay => hack to allow additionalparams
    if(!params[:redirectparam].nil?)
      url_options[:redirectparam] = params[:redirectparam]
    end
    redirect_to url_options, :status => status
  end
end