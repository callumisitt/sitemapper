class Report
  require './config/mail.rb'

  def initialize(site, report)
    @site = site
    @report = report
    @config = YAML.load_file('./config/mail.yaml')
  end

  def deliver
    site = @site
    report = @report
    config = @config

    Mail.deliver do
      from    config['report']['from']
      to      config['report']['to']
      subject "#{site['name']} Sitemap Report"
      body    report
    end
  end
end
