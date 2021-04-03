module Pdf
  class AssetsCustody < Pdf::Base
    def extract_assets_position
      assets_data = []
      assets = @reader.page(1)
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