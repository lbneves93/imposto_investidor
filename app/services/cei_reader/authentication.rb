module CeiReader
  require 'watir'

  class Authentication
    def initialize(cpf, password)
      @url = 'https://ceiapp.b3.com.br/CEI_Responsivo/login.aspx'
      @cpf = cpf
      @password = password
      args = ['--headless', '--no-sandbox', '--disable-dev-shm-usage']
      @browser = Watir::Browser.new(:chrome, args: args)
    end

    def signin
      @browser.goto(@url)
      @browser.text_field(name: 'ctl00$ContentPlaceHolder1$txtLogin').set(@cpf)
      @browser.text_field(name: 'ctl00$ContentPlaceHolder1$txtSenha').set(@password)
      @browser.input(name: 'ctl00$ContentPlaceHolder1$btnLogar').click
      @browser.span(id: 'ctl00_lblNome').wait_until(&:present?)
      @browser
    end
  end
end