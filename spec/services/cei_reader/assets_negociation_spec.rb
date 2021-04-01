require 'rails_helper'

RSpec.describe CeiReader::AssetsNegociation, type: :service do
  describe '.search' do
    subject(:assets_negociation) do
      described_class.new(@cei_reader)
    end

    before do
      params = { institution: '308', year: Time.zone.now.year-1 }
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
end