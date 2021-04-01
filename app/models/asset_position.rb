class AssetPosition < ApplicationRecord

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

  after_initialize :load_current_year

  def update_assets_position(cei_assets_negociation, cei_assets_custody)
    return "Assets for #{@current_year-1} already updated." unless asset_position_updated?

    last_position = AssetPosition.where(year: @current_year-2)

    cei_assets_custody.each do |asset_custody|
      asset_negociation = cei_assets_negociation.find{|asset_negociation| asset_negociation[:code] == asset_custody[:code]}
      asset_last_position = last_position.find{|asset_last_position| asset_last_position[:code] == asset_custody[:code]}

      asset_total_price = calculate_asset_total_price(asset_negociation, asset_last_position)

      AssetPosition.create(
        code: asset_custody[:code], 
        year: @current_year-1, 
        quotas: asset_custody[:quotas], 
        total_cost: asset_total_price
      )
    end
  end

  def irpf_assets_and_rights
    assets_position = AssetPosition.where(year: @current_year-1)
    return "Needs to update assets position for #{@current_year-1}" if assets_position.empty?

    assets_and_rights = []
    assets_position.each do |asset|
      return "Provide name and cnpj for the new asset #{asset.code}." if ASSETS_NAME[asset.code.to_sym].nil?

      assets_and_rights << {
        codigo: IRPF_ASSETS_CODE,
        localizacao: IRPF_ASSETS_LOCATION,
        cnpj: ASSETS_NAME[asset.code.to_sym][:cnpj],
        discriminacao: asset_position_description(asset),
        situacao_anterior: asset_old_total_cost(asset),
        situacao_atual: asset.total_cost.to_f
      }
    end

    assets_and_rights
  end

  def load_current_year
    @current_year ||= Time.zone.now.year
  end

  private

  def calculate_asset_total_price(asset_negociation, asset_last_position)
    if asset_negociation.present? && asset_last_position.present?
      avg_buy_price = asset_negociation[:buy_sell_diff].positive? ? asset_negociation[:avg_buy_price] : asset_last_position.total_cost/asset_last_position.quotas
      return asset_last_position.total_cost + (asset_negociation[:buy_sell_diff] * avg_buy_price)
    elsif asset_last_position.present?
      return asset_last_position.total_cost
    elsif asset_negociation.present?
      return asset_negociation[:buy_sell_diff] * asset_negociation[:avg_buy_price]
    end  
  end

  def asset_position_updated?
    assets_position = AssetPosition.where(year: @current_year-1)
    assets_position.empty?
  end

  def asset_position_description(asset)
    "#{asset.quotas} ações de #{ASSETS_NAME[asset.code.to_sym][:name]}. "+
    "Código de negociação: #{asset.code}."
  end

  def asset_old_total_cost(asset)
    old_asset_position = AssetPosition.find_by(year: @current_year-2, code: asset.code)
    return 0.00 if old_asset_position.nil?
    old_asset_position.total_cost.to_f
  end
end
