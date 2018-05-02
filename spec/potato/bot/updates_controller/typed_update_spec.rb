RSpec.describe Potato::Bot::UpdatesController::TypedUpdate do
  include_context 'potato/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Potato::Bot::UpdatesController) do
      include described_class
    end
  end

  context 'when `update` is a virtus model' do
    subject { controller }
    %w[
      message
      inline_query
      chosen_inline_result
    ].each do |type|
      context "with #{type}" do
        type_class = Potato::Bot::Types.const_get(type.camelize)
        let(:payload_type) { type }
        let(:payload) { {} }
        its(:payload_type) { should eq payload_type }
        its(:payload) { should be_instance_of type_class }
      end
    end
  end
end
