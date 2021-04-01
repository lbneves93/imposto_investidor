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
      @browser.button(id: 'ctl00_ContentPlaceHolder1_btnVersaoEXCEL').click
      sleep 7
    end
    
    def self.extract_assets_position(file_path)
      return 'File doesn\'t exists. Please download file first.' unless File.exist?(file_path)

      assets_data = []
      spreadsheet = Roo::Excel.new(file_path)

      spreadsheet.each_with_index do |row, idx|
        next if idx < 20
        row = row.compact
        next if row.empty?
        break if row[0] == 'VALORIZAÇÃO EM REAIS'
        
        assets_data << { code: "#{row[3].strip}F", quotas: row[4].to_i }
      end

      assets_data
    end
  end
end