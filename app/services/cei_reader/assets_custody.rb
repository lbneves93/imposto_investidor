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
    
    def self.extract_assets_position(file_path)
      return 'File doesn\'t exists. Please download file first.' unless File.exist?(file_path)

      assets_data = []
      reader = PDF::Reader.new(file_path)

      assets = reader.page(1)
            .to_s
            .split("Ativo                    Especif.      Cód. Neg.                   Saldo     Cotação             Valor")[1]
            .split("\nVALORIZAÇÃO EM REAIS").first.split(/\n/)
            .reject{|element| element.empty? }

      assets.each do |asset|
          asset = asset.split(/  /).reject{|element| element.empty?}.last(4)
          assets_data << {
              code: "#{asset[0].strip.gsub('#', '')}F",
              quotas: "#{asset[1].strip}".to_i
          }
      end

      assets_data
    end
  end
end