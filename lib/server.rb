class Server
  def initialize(server, site)
    @server = server
    @site = site
  end
  
  def upload_file(file)
    remote { upload! "./#{file}", @site['sitemap_location'] }
  end
  
  private
  def remote(site = @site, &block)
    server = SSHKit::Host.new("#{@server['user']}@#{@server['domain']}")
    SSHKit::Coordinator.new(server).each in: :sequence do
      @site = site
      instance_eval &block
    end
  end
end