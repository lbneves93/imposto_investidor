require 'rails_helper'

RSpec.describe Pdf::AssetsCustody, type: :service do
  describe '#extract_assets_position' do
    context 'when assets custody file do not exists' do
      subject(:assets_custody_data) do
        file_path = "#{Rails.root}/invalid_file.pdf"
        described_class.new(file_path).open
      end

      it 'returns error message' do
        expect(assets_custody_data).to eq('File doesn\'t exists.')
      end
    end

    context 'when assets custody file exists' do
      subject(:assets_custody_data) do
        test_path = "#{Rails.root}/spec/fixtures/files/InfoCEI.pdf"
        described_class.new(test_path).open.extract_assets_position
      end

      it 'returns assets code and quotas' do
        expect(assets_custody_data).to eq([
          { code: "ABEV3F", quotas: 82},
          { code: "BTOW3F", quotas: 3},
          { code: "CIEL3F", quotas: 39},
          { code: "ENBR3F", quotas: 73},
          { code: "EGIE3F", quotas: 21},
          { code: "FLRY3F", quotas: 38},
          { code: "ITSA4F", quotas: 144},
          { code: "ITUB4F", quotas: 5},
          { code: "MGLU3F", quotas: 29},
          { code: "OIBR4F", quotas: 88},
          { code: "SMTO3F", quotas: 44},
          { code: "SQIA3F", quotas: 82},
          { code: "SUZB3F", quotas: 23},
          { code: "UGPA3F", quotas: 3},
          { code: "VALE3F", quotas: 7},
          { code: "WEGE3F", quotas: 4}
        ])
      end

      it 'returns 16 assets' do
        expect(assets_custody_data.count).to eq(16)
      end
    end
  end
end