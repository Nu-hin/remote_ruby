# frozen_string_literal: true

describe 'Running on the local host', type: :integration do
  subject(:ec) do
    RemoteRuby::ExecutionContext.new(**params)
  end

  include_context 'common examples'

  let(:params) do
    {
      working_dir: working_dir
    }.merge(additional_params)
  end

  let(:additional_params) { {} }

  let(:working_dir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(working_dir)
  end
end
