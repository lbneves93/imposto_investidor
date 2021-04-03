module CeiReader
  class AssetsCustody
    def initialize(browser)
      @browser = browser
      @url = 'https://ceiapp.b3.com.br/CEI_Responsivo/extrato-bmfbovespa.aspx'
    end

    def download(params)
      @browser.goto(@url)
      @browser.select(name: 'ctl00$ContentPlaceHolder1$ddlAgentes').select(params[:institution])
      @browser.select(name: 'ctl00$ContentPlaceHolder1$ddlFiltroMes').select(params[:period])
      @browser.button(id: 'ctl00_ContentPlaceHolder1_btnVersaoImpressao').click
      sleep 10
    end
  end
end