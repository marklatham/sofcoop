class ApplicationMailer < ActionMailer::Base
  default from: Sofcoop::Application.secrets.admin_email
  layout 'mailer'
end
