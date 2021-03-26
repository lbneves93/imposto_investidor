require 'rails_helper'

RSpec.describe CeiReader::AssetsNegociation, type: :service do
  describe '.search' do
    subject(:assets_negociation) do
      described_class.new(@cei_reader)
    end

    before do
      params = { institution: '308', year: '2020' }
      @assets_negociation_data ||= assets_negociation.search(params)
    end

    context 'with valid params' do
      it 'returns assets negociation' do
        expect(@assets_negociation_data.first).to include(
          code: /[A-Z]{4}\d{1,2}/,
          buy_count: a_kind_of(Integer),
          sell_count: a_kind_of(Integer),
          buy_sell_diff: a_kind_of(Integer),
          avg_buy_price: a_kind_of(BigDecimal),
          avg_sell_price: a_kind_of(BigDecimal)
        )
      end
    end
  end

  describe '.update_assets_position' do
    subject(:assets_negociation) do
      allow_any_instance_of(described_class).to receive(:search).and_return(assets_operation)
      described_class.new(@cei_reader)
    end

    before do
      AssetPosition.create(code: 'ABEV3F', year: year, quotas: 10, total_cost: 200.to_d)
      @assets_negociation = assets_negociation.update_assets_position
    end

    context 'when already update the asset position' do
      let(:assets_operation) do 
        [{
          code: 'ABEV3F', 
          buy_count: 10, 
          sell_count: 0,
          buy_sell_diff: 10,
          avg_buy_price: 10.to_d, 
          avg_sell_price: 0.to_d
        }]
      end

      let(:year) { Time.zone.now.year-1 }

      it 'returns message assets already updated' do
        expect(@assets_negociation).to eq("Assets for #{Time.zone.now.year-1} already updated.")
      end
    end

    context 'when needs to update the assets' do
      let(:year) { Time.zone.now.year-2 }

      context 'when bought more quotas for old asset' do
        let(:assets_operation) do 
          [{
            code: 'ABEV3F', 
            buy_count: 10, 
            sell_count: 0,
            buy_sell_diff: 10,
            avg_buy_price: 12.53.to_d, 
            avg_sell_price: 0.to_d
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
        let(:assets_operation) do 
          []
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
        let(:assets_operation) do 
          [{
            code: 'ABEV3F', 
            buy_count: 0, 
            sell_count: 10,
            buy_sell_diff: -10,
            avg_buy_price: 0.to_d, 
            avg_sell_price: 20.to_d
          }]
        end

        it 'creates a new assets_position for current year' do

          expect(AssetPosition.find_by(year: year+1, code: 'ABEV3F')).to have_attributes(
            code: 'ABEV3F',
            year: year+1,
            quotas: 0,
            total_cost: 0.to_d
          )
        end
      end

      context 'when sold just a few quotas for old asset' do
        let(:assets_operation) do 
          [{
            code: 'ABEV3F', 
            buy_count: 0, 
            sell_count: 2,
            buy_sell_diff: -2,
            avg_buy_price: 0.to_d, 
            avg_sell_price: 20.to_d
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
        let(:assets_operation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 0,
            buy_sell_diff: 10,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 0.to_d
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
        let(:assets_operation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 10,
            buy_sell_diff: 0,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 20.to_d
          }]
        end

        it 'creates a new assets_position for current year' do

          expect(AssetPosition.find_by(year: year+1, code: 'ITSA4F')).to have_attributes(
            code: 'ITSA4F',
            year: year+1,
            quotas: 0,
            total_cost: 0.to_d
          )
        end
      end

      context 'when bought quotas for new asset and sell a few quotas' do
        let(:assets_operation) do 
          [{
            code: 'ITSA4F', 
            buy_count: 10, 
            sell_count: 5,
            buy_sell_diff: 5,
            avg_buy_price: 10.to_d, 
            avg_sell_price: 20.to_d
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
    end  
  end
  
  describe '.irpf_assets_and_rights' do
    before do
      AssetPosition.create(code: 'ABEV3F', year: Time.zone.now.year-1, quotas: 10, total_cost: 200.to_d)
      AssetPosition.create(code: 'ITSA4F', year: Time.zone.now.year-1, quotas: 20, total_cost: 300.to_d)
      @assets_negociation = described_class.new(@cei_reader)
    end

    let(:expected_description) do
      "Código: 31 - Ações (inclusive as provenientes de linha telefônica).\n"+
      "Localização: 105 - Brasil\n"+
      "CNPJ: 07526557000100\n"+
      "Discriminação: 10 ações de AMBEV S.A. Código de negociação: ABEV3F.\n"+
      "Situação Anterior: #{abev_old_situation}\n"+
      "Situação Atual: 200.0\n\n"+
      "Código: 31 - Ações (inclusive as provenientes de linha telefônica).\n"+
      "Localização: 105 - Brasil\n"+
      "CNPJ: 61532644000115\n"+
      "Discriminação: 20 ações de ITAUSA INVESTIMENTOS ITAU SA. Código de negociação: ITSA4F.\n"+
      "Situação Anterior: #{itsa_old_situation}\n"+
      "Situação Atual: 300.0\n\n"
    end

    context 'when is first year investing' do
      let(:abev_old_situation) { '0,00' }
      let(:itsa_old_situation) { '0,00' }

      it 'returns section assets_and_rights for irpf filled' do
        expect(@assets_negociation.irpf_assets_and_rights).to eq(expected_description)
      end
    end

    context 'when is second year investing' do
      let(:abev_old_situation) { '100.0' }
      let(:itsa_old_situation) { '0,00' }

      it 'returns section assets_and_rights for irpf filled' do
        AssetPosition.create(code: 'ABEV3F', year: Time.zone.now.year-2, quotas: 5, total_cost: 100.to_d)
        expect(@assets_negociation.irpf_assets_and_rights).to eq(expected_description)
      end
    end

    context 'when the assets position needs update' do
      it 'returns message to update assets position' do
        AssetPosition.find_by(code: 'ABEV3F').delete
        AssetPosition.find_by(code: 'ITSA4F').delete
        expect(@assets_negociation.irpf_assets_and_rights).to eq("Needs to update assets position for #{Time.zone.now.year-1}")
      end
    end
  end
end