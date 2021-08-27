# frozen_string_literal: true

RSpec.describe RemoteRuby::Serializer do
  it 'encodes variables' do
    data = {
      integer: 1,
      float: 1.0,
      string: 'Hello',
      time: Time.now,
      symbol: :theta,
      array: [3, 'Hello', 1.0],
      hash: { e: 3, c: 1.0, f: 'Hi' }
    }

    encoded = described_class.serialize(data)
    puts encoded
    decoded = described_class.deserialize(encoded)

    expect(decoded).to eq(data)
  end
end
