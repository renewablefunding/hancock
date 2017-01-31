describe Hancock::Envelope::DocusignEnvelope do
  let(:envelope) {
    Hancock::Envelope.new(:identifier => 'maui')
  }
  subject { described_class.new(envelope) }

  describe '.new' do
    it 'requires an envelope identifier' do
      expect{ described_class.new(double(Hancock::Envelope, :identifier => nil)) }
        .to raise_error('envelope requires an identifier')
    end
  end

  describe '#viewing_url' do
    it 'makes a request to Docusign' do
      expect(Hancock::Request).to receive(:send_post_request)
        .with('/envelopes/maui/views/sender', '{}')

      subject.viewing_url
    end
  end

  describe '#get_lock' do
    it 'makes a request to Docusign' do
      expect(Hancock::Request).to receive(:send_get_request)
        .with('/envelopes/maui/lock')

      subject.get_lock
    end
  end

  describe '#resend_email' do
    it 'makes a request to Docusign' do
      recipient = instance_double(Hancock::Recipient, name: "MJ", email: "mj@example.com", identifier: "6a")
      expect(Hancock::Request).to receive(:send_put_request)
        .with(
          '/envelopes/maui/recipients?resend_envelope=true',
          "{\"signers\":[{\"recipientId\":\"6a\",\"name\":\"MJ\",\"email\":\"mj@example.com\"}]}"
        )

      subject.resend_email(recipient)
    end
  end
end
