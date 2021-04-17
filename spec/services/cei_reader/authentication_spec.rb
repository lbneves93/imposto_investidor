require 'rails_helper'

RSpec.describe CeiReader::Authentication, type: :service do
  describe '#signin' do
    context 'with valid credentials' do
      it 'returns home page logged' do
        expect(@cei_reader.span(id: 'ctl00_lblNome').text).to include('LEONARDO BATISTA NEVES')
      end
    end
  end
end