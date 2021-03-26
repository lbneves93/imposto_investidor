module CeiReader
  class AssetsNegociation

    ASSETS_NAME = {
      ABEV3F: { name: 'AMBEV S.A', cnpj: '07526557000100' },
      BTOW3F: { name: 'B2W DIGITAL', cnpj: '00776574000156' },
      CIEL3F: { name: 'CIELO S/A', cnpj: '01027058000191' },
      EGIE3F: { name: 'ENGIE BRASIL ENERGIA S.A', cnpj: '02474103000119' },
      ENBR3F: { name: 'EDP - ENERGIAS DO BRASIL SA', cnpj: '03983431000103' },
      FLRY3F: { name: 'FLEURY S/A', cnpj: '60840055000131' },
      ITSA4F: { name: 'ITAUSA INVESTIMENTOS ITAU SA', cnpj: '61532644000115' },
      ITUB4F: { name: 'ITAU UNIBANCO HOLDING S.A.', cnpj: '60872504000123'},
      MGLU3F: { name: 'MAGAZINE LUIZA SA', cnpj: '47960950000121' },
      OIBR4F: { name: 'OI S.A', cnpj: '76535764000143' },
      SMTO3F: { name: 'SAO MARTINHO S/A', cnpj: '51466860000156' },
      SQIA3F: { name: 'SINQIA S.A', cnpj: '04065791000199' },
      SUZB3F: { name: 'SUZANO SA', cnpj: '16404287000155' },
      TIET11F: { name: 'AES TIETE ENERGIA', cnpj: '04128563000110' },
      TRPL4F: { name: 'CIA DE TRANSM DE EN ELETR PTA', cnpj: '02998611000104' },
      UGPA3F: { name: 'ULTRAPAR PARTICIPACOES S/A', cnpj: '33256439000139' },
      VALE3F: { name: 'VALE S.A', cnpj: '33592510000154' },
      WEGE3F: { name: 'WEG S.A', cnpj: '84429695000111' }
    }

    IRPF_ASSETS_CODE = '31 - Ações (inclusive as provenientes de linha telefônica)'
    IRPF_ASSETS_LOCATION = '105 - Brasil'

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

    def update_assets_position
      current_year = Time.zone.now.year
      assets_position = AssetPosition.where(year: current_year-1)

      return "Assets for #{current_year-1} already updated." unless assets_position.empty?

      current_position = search({institution: '308', year: current_year-1})
      last_position = AssetPosition.where(year: current_year-2)

      last_position.each do |last_asset|
        current_asset = current_position.select{ |asset| asset[:code] == last_asset.code }.first

        if current_asset.present?
          new_asset= calculate_new_assets_position(last_asset, current_asset, current_year)
        else
          new_asset = keep_assets_position(last_asset, current_year)
        end
        
        AssetPosition.create(new_asset)
      end

      new_assets_on_wallet = current_position.pluck(:code) - last_position.pluck(:code)
      return if new_assets_on_wallet.empty?

      create_new_assets_on_wallet(new_assets_on_wallet, current_position, current_year)
    end

    def irpf_assets_and_rights
      current_year = Time.zone.now.year
      assets_position = AssetPosition.where(year: current_year-1)
      return "Needs to update assets position for #{current_year-1}" if assets_position.empty?

      assets_and_rights = ''
      assets_position.each do |asset|
        return "Provide name and cnpj for the new asset #{asset.code}." if ASSETS_NAME[asset.code.to_sym].nil?
        assets_and_rights += 
          "Código: #{IRPF_ASSETS_CODE}.\n"+
          "Localização: #{IRPF_ASSETS_LOCATION}\n"+
          "CNPJ: #{ASSETS_NAME[asset.code.to_sym][:cnpj]}\n"+
          "Discriminação: #{asset_position_description(asset)}\n"+
          "Situação Anterior: #{asset_old_total_cost(asset)}\n"+
          "Situação Atual: #{asset.total_cost}\n\n"
      end

      puts assets_and_rights
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

    def calculate_new_assets_position(last_asset, current_asset, current_year)
      new_quotas = last_asset.quotas + current_asset[:buy_sell_diff]
      new_total_cost = sum_total_cost(last_asset, current_asset, new_quotas)
      {code: current_asset[:code], year: current_year-1, quotas: new_quotas, total_cost: new_total_cost}
    end

    def keep_assets_position(last_asset, current_year)
      last_asset.year = current_year - 1
      last_asset.attributes.symbolize_keys.extract!(:code, :year, :quotas, :total_cost)
    end

    def sum_total_cost(last_asset, current_asset, new_quotas)
      return 0.to_d if new_quotas == 0
      avg_buy_price = current_asset[:buy_sell_diff].positive? ? current_asset[:avg_buy_price] : last_asset.total_cost/last_asset.quotas
      last_asset.total_cost + (current_asset[:buy_sell_diff] * avg_buy_price)
    end

    def create_new_assets_on_wallet(new_assets_on_wallet, current_position, current_year)
      current_position.each do |asset|
        next unless new_assets_on_wallet.include?(asset[:code])

        total_cost = asset[:buy_sell_diff] * asset[:avg_buy_price]

        AssetPosition.create(
          code: asset[:code], 
          year: current_year-1, 
          quotas: asset[:buy_sell_diff],
          total_cost: total_cost
        )
      end
    end

    def asset_position_description(asset)
      "#{asset.quotas} ações de #{ASSETS_NAME[asset.code.to_sym][:name]}. "+
      "Código de negociação: #{asset.code}."
    end

    def asset_old_total_cost(asset)
      old_asset_position = AssetPosition.find_by(year: Time.zone.now.year-2, code: asset.code)
      return '0,00' if old_asset_position.nil?
      old_asset_position.total_cost.to_s
    end
  end
end