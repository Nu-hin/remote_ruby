# frozen_string_literal: true

describe 'Running on the local host', type: :integration do
  include_context 'shared examples'

  let(:adapter_specific_params) { { working_dir: working_dir } }

  let(:working_dir) do
    Dir.mktmpdir
  end

  after do
    FileUtils.remove_entry(working_dir)
  end
end
