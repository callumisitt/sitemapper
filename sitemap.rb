#!/usr/bin/ruby

class Sitemap
  require 'rubygems'
  require 'bundler/setup'

  Bundler.require(:default)
  Dir['./lib/*.rb'].each {|file| require file}

  EXCLUDE_URLS = ['http', 'https', 'www', 'mailto', 'javascript', '#', '/system', '/pdfs']

  def initialize(site)
    @site = site
    @server = ARGV[0]
    @urls, @error_urls = [], []
    @report = {errors: [], ping: []}
    @root_url = @site['domain']
    @agent = Mechanize.new
  end

  def start
    crawl_site
    create_sitemap
    upload_sitemap
    unless @server == 'staging'
      ping_search_engines
      report_results
    end
  end

  def excluded_paths
    paths = []
    if @site['excluded_paths']
      @site['excluded_paths'].each do |path|
        if path['path'].start_with?('*')
          paths << { path: path['path'].sub('*', ''), wildcard: true }
        else
          paths << path['path']
        end
      end
    end
    EXCLUDE_URLS.each { |url| paths << url }
    paths
  end

  def is_excluded?(url)
    return true if !url || url.empty?

    excluded_paths.any? do |path|
      if path.class == Hash && path[:wildcard]
        url.include?(path[:path])
      else
        url.start_with?(path)
      end
    end
  end

  def parse_url(url)
    return url if url == @root_url || is_excluded?(url)
    url.start_with?('/') ? url : "/#{url}"
  end

  def crawl_site(url = @root_url)
    url = parse_url(url)
    page = @agent.get(url)

    puts url
    @urls << url

    page.links.each do |link|
      link = parse_url(link.href)
      unless is_excluded?(link) || @urls.include?(link) || @error_urls.include?(link)
        crawl_site(link)
      end
    end
  rescue Mechanize::ResponseCodeError, NoMethodError => e
    puts "Error #{e}"
    @report[:errors] << e
    @error_urls << url
  end

  def create_sitemap
    sitemap = XmlSitemap::Map.new(@root_url.sub(/(http|https):\/\//, ''), {home: false, root: false})
    @urls.each do |url|
      video = Video.new(url, @root_url)
      sitemap.add url, video.details
    end
    sitemap.render_to("sitemaps/#{@server}/#{@site['name']}.xml")
  end

  def upload_sitemap
    servers = YAML.load_file('sites/servers.yaml')
    site_server = servers['servers'].select { |servers| servers['server'] == @server }[0] # so much server
    server = Server.new(site_server, @site)
    server.upload_file("sitemaps/#{@server}/#{@site['name']}.xml")
  rescue SSHKit::Runner::ExecuteError => e
    puts "Error #{e}"
    @report[:errors] << e
  end

  def ping_search_engines
    google = HTTParty.get("http://www.google.com/webmasters/sitemaps/ping?sitemap=#{@site['domain']}/sitemap.xml")
    @report[:ping] << "Google: #{google.response.code} #{google.response.message}"
    bing = HTTParty.get("http://www.bing.com/webmaster/ping.aspx?siteMap=#{@site['domain']}/sitemap.xml")
    @report[:ping] << "Bing: #{bing.response.code} #{bing.response.message}"
  end

  def report_results
    report_message = %Q{#{@site['name']} sitemap updated with #{@urls.count} URLs

Search Engines pinged:
#{@report[:ping].join("\n")}

#{@report[:errors].count} errors found
#{@report[:errors].join("\n")}
    }
    report = Report.new(@site, report_message)
    report.deliver
  end
end

sitemap = YAML.load_file("sites/#{ARGV[0]}/#{ARGV[1]}.yaml")

sitemap['sites'].each do |site|
  puts "Sitemapping #{site['name']}"

  sitemap = Sitemap.new(site)
  sitemap.start
end
