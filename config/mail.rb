config = YAML.load_file('./config/mail.yaml')

Mail.defaults do
  delivery_method :smtp, {
    address: 'smtp.mandrillapp.com',
    port: 587,
    domain: config['mandrill']['domain'],
    user_name: config['mandrill']['user_name'],
    password: config['mandrill']['password'],
    enable_starttls_auto: false
  }
end
