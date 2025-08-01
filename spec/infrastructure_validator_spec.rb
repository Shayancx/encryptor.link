# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Infrastructure::Validator do
  let(:validator) { described_class.new }

  it 'adds and clears errors' do
    validator.add_error(:field, 'bad')
    expect(validator.errors).not_to be_empty
    validator.clear_errors
    expect(validator.errors).to be_empty
  end

  it 'validates numeric range' do
    expect(validator.range_valid?(5, 1..10, :num)).to be true
    expect(validator.range_valid?(0, 1..10, :num)).to be false
    expect(validator.errors.last[:message]).to include('between')
  end

  it 'validates format with regex' do
    expect(validator.format_valid?('abc', /\A[a-z]+\z/, :name)).to be true
    expect(validator.format_valid?('123', /\A[a-z]+\z/, :name)).to be false
    expect(validator.errors.last[:field]).to eq(:name)
  end
end
