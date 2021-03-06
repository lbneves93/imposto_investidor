require 'rails_helper'

RSpec.describe AssetPosition, type: :model do
  describe '#update_assets_position' do
    before do
      AssetPosition.create(code: 'ABEV3F', year: year, quotas: 10, total_cost: 200.to_d)
      @assets_position = described_class.new.update_assets_position(assets_negociation, assets_custody)
    end

    context 'when already update the asset position' do
      let(:assets_negociation) { [build_assets_negociation_hash('ABEV3F', 10, 0, 10, 10, 0)] }
      let(:assets_custody){ [{ code: 'ABEV3F', quotas: 10 }] }
      let(:year) { Time.zone.now.year-1 }

      it 'returns message assets already updated' do
        expect(@assets_position).to eq("Assets for #{Time.zone.now.year-1} already updated.")
      end
    end

    context 'when needs to update the assets' do
      let(:year) { Time.zone.now.year-2 }

      context 'when bought more quotas for old asset' do
        let(:assets_negociation) { [build_assets_negociation_hash('ABEV3F', 10, 0, 10, 12.53, 0)] }
        let(:assets_custody){ [{ code: 'ABEV3F', quotas: 20 }] }

        it 'creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ABEV3F')).to have_attributes(
            code: 'ABEV3F',
            year: year+1,
            quotas: 20,
            total_cost: 325.3.to_d
          )
        end
      end

      context 'when not bought more quotas for old asset' do
        let(:assets_negociation) { [] }
        let(:assets_custody){ [{ code: 'ABEV3F', quotas: 10 }] }

        it 'creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ABEV3F')).to have_attributes(
            code: 'ABEV3F',
            year: year+1,
            quotas: 10,
            total_cost: 200.to_d
          )
        end
      end

      context 'when sold all quotas for old asset' do
        let(:assets_negociation) { [build_assets_negociation_hash('ABEV3F', 0, 10, -10, 0, 20)] }
        let(:assets_custody){ [] }

        it 'not creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ABEV3F')).to be_nil
        end
      end

      context 'when sold just a few quotas for old asset' do
        let(:assets_negociation) { [build_assets_negociation_hash('ABEV3F', 0, 2, -2, 0, 20)] }
        let(:assets_custody){ [{ code: 'ABEV3F', quotas: 8 }] }   

        it 'creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ABEV3F')).to have_attributes(
            code: 'ABEV3F',
            year: year+1,
            quotas: 8,
            total_cost: 160.to_d
          )
        end
      end

      context 'when bought quotas for new asset' do
        let(:assets_negociation) { [build_assets_negociation_hash('ITSA4F', 10, 0, 10, 10, 0)] }
        let(:assets_custody){ [{ code: 'ITSA4F', quotas: 10 }] }

        it 'creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ITSA4F')).to have_attributes(
            code: 'ITSA4F',
            year: year+1,
            quotas: 10,
            total_cost: 100.to_d
          )
        end
      end

      context 'when bought quotas for new asset and sell all' do
        let(:assets_negociation) { [build_assets_negociation_hash('ITSA4F', 10, 10, 0, 10, 20)] }
        let(:assets_custody){ [] }

        it 'not creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ITSA4F')).to be_nil
        end
      end

      context 'when bought quotas for new asset and sell a few quotas' do
        let(:assets_negociation) { [build_assets_negociation_hash('ITSA4F', 10, 5, 5, 10, 20)] }
        let(:assets_custody){ [{ code: 'ITSA4F', quotas: 5 }] }

        it 'creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ITSA4F')).to have_attributes(
            code: 'ITSA4F',
            year: year+1,
            quotas: 5,
            total_cost: 50.to_d
          )
        end
      end

      context 'when new asset split the quotas in 1:2 factor' do
        let(:assets_negociation) { [build_assets_negociation_hash('ITSA4F', 10, 0, 10, 10, 0)] }
        let(:assets_custody){ [{ code: 'ITSA4F', quotas: 20 }] }

        it 'creates a new assets_position for current year' do

          expect(AssetPosition.find_by(year: year+1, code: 'ITSA4F')).to have_attributes(
            code: 'ITSA4F',
            year: year+1,
            quotas: 20,
            total_cost: 100.to_d
          )
        end
      end
    end  
  end

  describe '#irpf_assets_and_rights' do
    before do
      AssetPosition.create(code: 'ABEV3F', year: Time.zone.now.year-1, quotas: 10, total_cost: 200.to_d)
      AssetPosition.create(code: 'ITSA4F', year: Time.zone.now.year-1, quotas: 20, total_cost: 300.to_d)
      @asset_position = described_class.new
    end

    let(:expected_description) do
      [
        {
          codigo: '31 - Ações (inclusive as provenientes de linha telefônica)',
          localizacao: '105 - Brasil',
          cnpj: '07526557000100',
          discriminacao: '10 ações de AMBEV S.A. Código de negociação: ABEV3F.',
          situacao_anterior: abev_old_situation,
          situacao_atual: 200.0
        },
        {
          codigo: '31 - Ações (inclusive as provenientes de linha telefônica)',
          localizacao: '105 - Brasil',
          cnpj: '61532644000115',
          discriminacao: '20 ações de ITAUSA INVESTIMENTOS ITAU SA. Código de negociação: ITSA4F.',
          situacao_anterior: itsa_old_situation,
          situacao_atual: 300.0
        }
      ]
    end

    context 'when is first year investing' do
      let(:abev_old_situation) { 0.00 }
      let(:itsa_old_situation) { 0.00 }

      it 'returns section assets_and_rights for irpf filled' do
        expect(@asset_position.irpf_assets_and_rights).to eq(expected_description)
      end
    end

    context 'when is second year investing' do
      let(:abev_old_situation) { 100.0 }
      let(:itsa_old_situation) { 0.00 }

      it 'returns section assets_and_rights for irpf filled' do
        AssetPosition.create(code: 'ABEV3F', year: Time.zone.now.year-2, quotas: 5, total_cost: 100.to_d)
        expect(@asset_position.irpf_assets_and_rights).to eq(expected_description)
      end
    end

    context 'when the assets position needs update' do
      it 'returns message to update assets position' do
        AssetPosition.find_by(code: 'ABEV3F').delete
        AssetPosition.find_by(code: 'ITSA4F').delete
        expect(@asset_position.irpf_assets_and_rights).to eq("Needs to update assets position for #{Time.zone.now.year-1}")
      end
    end
  end
end

def build_assets_negociation_hash(code, buy_count, sell_count, buy_sell_diff, avg_buy_price, avg_sell_price)
  {
    code: code, 
    buy_count: buy_count, 
    sell_count: sell_count,
    buy_sell_diff: buy_sell_diff,
    avg_buy_price: avg_buy_price.to_d, 
    avg_sell_price: avg_sell_price.to_d
  }
end