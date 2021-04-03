namespace :IRPF do
  # rails 'IRPF:assets_and_rights[cpf_cei, senha_cei]'
  desc 'Fornece dados para declaração do imposto de renda.'

  task :assets_and_rights, [:user, :password] => :environment do |t, args|
    pp 'Autenticando no CEI...'
    cei_reader = CeiReader::Authentication.new(args[:user], args[:password])
    browser = cei_reader.signin
    
    pp 'Autenticação completa!'
    assets_negociation = CeiReader::AssetsNegociation.new(browser)
    assets_custody = CeiReader::AssetsCustody.new(browser)
    current_year = Time.zone.now.year
    
    pp 'Baixando arquivo de custodia de ativos no CEI...'
    assets_custody.download({ institution: '308', period: "30/12/#{current_year-1} 00:00:00" })
    pp 'Download do arquivo de custodia completo!'
    
    pp 'Baixando dados de negociação de ativos no CEI...'
    assets_negociation_cei = assets_negociation.search({institution: '308', year: current_year-1 })
    
    pp 'Extraindo numero de cotas de ativos do arquivo de custodia de ativos...'
    assets_custody_pdf = Pdf::AssetsCustody.new("#{Rails.root}/InfoCEI.pdf")
    assets_custody_cei = assets_custody_pdf.open.extract_assets_position
    
    pp 'Atualizando posição de ativos para o ano atual...'
    asset_position = AssetPosition.new
    asset_position.update_assets_position(assets_negociation_cei, assets_custody_cei)
    pp 'Atualização completa!'
    pp "Gerando relatório para declaração de bens e direitos..."
    pp asset_position.irpf_assets_and_rights
  end
end