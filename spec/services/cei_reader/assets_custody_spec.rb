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
end