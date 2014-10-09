Noosfero.default_locale = 'pt'
FastGettext.locale = Noosfero.default_locale
I18n.locale = Noosfero.default_locale

# don't work with delayed job
#Time.zone = 'America/Sao_Paulo'

ActionMailer::Base.delivery_method = :sendmail
