require 'rails_helper'

RSpec.describe AssetPosition, type: :model do
  describe '.update_assets_position' do
    before do
      AssetPosition.create(code: 'ABEV3F', year: year, quotas: 10, total_cost: 200.to_d)
      @assets_position = described_class.new.update_assets_position(assets_negociation, assets_custody)
    end

    context 'when already update the asset position' do
      let(:assets_negociation) do 
        [{
          code: 'ABEV3F', 
          buy_count: 10, 
          sell_count: 0,
          buy_sell_diff: 10,
          avg_buy_price: 10.to_d, 
          avg_sell_price: 0.to_d
        }]
      end

      let(:assets_custody) do
        [{
          code: 'ABEV3F',
          quotas: 10
        }]
      end

      let(:year) { Time.zone.now.year-1 }

      it 'returns message assets already updated' do
        expect(@assets_position).to eq("Assets for #{Time.zone.now.year-1} already updated.")
      end
    end

    context 'when needs to update the assets' do
      let(:year) { Time.zone.now.year-2 }

      context 'when bought more quotas for old asset' do
        let(:assets_negociation) do 
          [{
            code: 'ABEV3F', 
            buy_count: 10, 
            sell_count: 0,
            buy_sell_diff: 10,
            avg_buy_price: 12.53.to_d, 
            avg_sell_price: 0.to_d
          }]
        end

        let(:assets_custody) do
          [{
            code: 'ABEV3F',
            quotas: 20
          }]
        end

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
        let(:assets_negociation) do 
          []
        end

        let(:assets_custody) do
          [{
            code: 'ABEV3F',
            quotas: 10
          }]
        end

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
        let(:assets_negociation) do 
          [{
            code: 'ABEV3F', 
            buy_count: 0, 
            sell_count: 10,
            buy_sell_diff: -10,
            avg_buy_price: 0.to_d, 
            avg_sell_price: 20.to_d
          }]
        end

        let(:assets_custody) do
          []
        end

        it 'not creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ABEV3F')).to be_nil
        end
      end

      context 'when sold just a few quotas for old asset' do
        let(:assets_negociation) do 
          [{
            code: 'ABEV3F', 
            buy_count: 0, 
            sell_count: 2,
            buy_sell_diff: -2,
            avg_buy_price: 0.to_d, 
            avg_sell_price: 20.to_d
          }]
        end

        let(:assets_custody) do
          [{
            code: 'ABEV3F',
            quotas: 8
          }]
        end

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
        let(:assets_negociation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 0,
            buy_sell_diff: 10,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 0.to_d
          }]
        end

        let(:assets_custody) do
          [{
            code: 'ITSA4F',
            quotas: 10
          }]
        end

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
        let(:assets_negociation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 10,
            buy_sell_diff: 0,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 20.to_d
          }]
        end

        let(:assets_custody) do
          []
        end

        it 'not creates a new assets_position for current year' do
          expect(AssetPosition.find_by(year: year+1, code: 'ITSA4F')).to be_nil
        end
      end

      context 'when bought quotas for new asset and sell a few quotas' do
        let(:assets_negociation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 5,
            buy_sell_diff: 5,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 20.to_d
          }]
        end

        let(:assets_custody) do
          [{
            code: 'ITSA4F',
            quotas: 5
          }]
        end

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
        let(:assets_negociation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 0,
            buy_sell_diff: 10,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 0.to_d
          }]
        end

        let(:assets_custody) do
          [{
            code: 'ITSA4F',
            quotas: 20
          }]
        end

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

  describe '.irpf_assets_and_rights' do
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