module CeiReader
  class AssetsNegociation

    def initialize(browser)
      @browser = browser
      @url = 'https://ceiapp.b3.com.br/CEI_Responsivo/negociacao-de-ativos.aspx'
    end

    def search(params)
      start_date = "01/01/#{params[:year]}"
      end_date = "31/12/#{params[:year]}"

      @browser.goto(@url)
      @browser.select(name: 'ctl00$ContentPlaceHolder1$ddlAgentes').select(params[:institution])
      @browser.text_field(name: 'ctl00$ContentPlaceHolder1$txtDataDeBolsa').set(start_date)
      @browser.text_field(name: 'ctl00$ContentPlaceHolder1$txtDataAteBolsa').set(end_date)
      @browser.input(name: 'ctl00$ContentPlaceHolder1$btnConsultar').click
      div_summary_negociation = 'ctl00_ContentPlaceHolder1_rptAgenteBolsa_ctl00_rptContaBolsa_ctl00_pnResumoNegocios'
      @browser.div(id: div_summary_negociation).wait_until(&:present?)
      table = @browser.div(id: div_summary_negociation).table
      extract_summary_negociation_data(table)
    end

    private

    def extract_summary_negociation_data(table)
      data = []
      
      table.each do |row|
        next if row.rowindex == 0
        data << {
          code: row[0].text, 
          buy_count: row[2].text.to_i, 
          sell_count: row[3].text.to_i,
          buy_sell_diff: row[2].text.to_i - row[3].text.to_i,
          avg_buy_price: row[4].text.gsub(',', '.').to_d, 
          avg_sell_price: row[5].text.gsub(',', '.').to_d
        }
      end
      
      data
    end
  end
end