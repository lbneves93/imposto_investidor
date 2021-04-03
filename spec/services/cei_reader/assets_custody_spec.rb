require 'rails_helper'

RSpec.describe CeiReader::AssetsCustody, type: :service do
  describe '.download' do
    subject(:assets_custody) do
      described_class.new(@cei_reader)
    end

    context 'with valid period' do
      let(:params) do
        { institution: '308', period: "30/12/#{Time.zone.now.year-1} 00:00:00" }
      end

      it 'save the assets custody pdf for given period' do
        assets_custody.download(params)
        expect(File.exist?("#{Rails.root}/InfoCEI.pdf")).to be_truthy
      end
    end

    after(:all) do
      File.delete("#{Rails.root}/InfoCEI.pdf")
    end
  end

  describe '.extract_assets_position' do
    context 'when assets custody file do not exists' do
      subject(:assets_custody_data) do
        file_path = "#{Rails.root}/InfoCEI.pdf"
        described_class.extract_assets_position(file_path)
      end

      it 'returns error message' do
        expect(assets_custody_data).to eq('File doesn\'t exists. Please download file first.')
      end
    end

    context 'when assets custody file exists' do
      subject(:assets_custody_data) do
        test_path = "#{Rails.root}/spec/fixtures/files/InfoCEI.pdf"
        described_class.extract_assets_position(test_path)
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