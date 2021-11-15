# frozen_string_literal: true

describe RemoteRuby::SourceExtractor do
  subject { described_class.new }

  # rubocop:disable Layout/HeredocIndentation, Layout/IndentationWidth
  let(:desired_result) do
<<-RUBY
a.foo1
foo2
foo3(bar)
x = 3
if x == 4
  y = 5
end
unless y
  return 6
end
y
RUBY
  end
  # rubocop:enable Layout/HeredocIndentation, Layout/IndentationWidth

  # rubocop:disable Layout/IndentationConsistency, Style/IfUnlessModifier
  # rubocop:disable Lint/UnusedBlockArgument, Layout/LineLength
  context 'with do-block' do
    context 'well-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract do
            # :nocov:
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            return 6 unless y

            y
            # :nocov:
          end

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          res = subject.extract do |context, a, b|
            # :nocov:
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            unless y
              return 6
            end

            y
            # :nocov:
          end

          expect(res).to eq(desired_result)
        end
      end
    end

    # rubocop:disable Layout/MultilineBlockLayout, Style/Semicolon
    context 'ill-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          # :nocov:
          res = subject.extract do a.foo1; foo2; foo3(bar); x = 3
            y = 5 if x == 4
            return 6 unless y

            y
          end
          # :nocov:

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          # :nocov:
          res = subject.extract do |context, a, b| a.foo1; foo2; foo3(bar); x = 3
            y = 5 if x == 4
            return 6 unless y

            y
          end
          # :nocov:

          expect(res).to eq(desired_result)
        end
      end
    end
    # rubocop:enable Layout/MultilineBlockLayout, Style/Semicolon
  end

  context 'with {}-block' do
    # rubocop:disable Style/Semicolon
    context 'well-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          # :nocov:
          res = subject.extract { a.foo1; foo2; foo3(bar); x = 3; y = 5 if x == 4; return 6 unless y; y }

          # :nocov:

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          # :nocov:
          res = subject.extract { |context, a, b| a.foo1; foo2; foo3(bar); x = 3; y = 5 if x == 4; return 6 unless y; y }

          # :nocov:

          expect(res).to eq(desired_result)
        end
      end
    end
    # rubocop:enable Style/Semicolon

    context 'ill-formatted' do
      # rubocop:disable Style/BlockDelimiters
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract {
            # :nocov:
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            return 6 unless y

            y
            # :nocov:
          }

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          # :nocov:
          res = subject.extract { |context, a, b|
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            return 6 unless y

            y
          }
          # :nocov:

          expect(res).to eq(desired_result)
        end
      end
    end
    # rubocop:enable Style/BlockDelimiters
  end
  # rubocop:enable Layout/IndentationConsistency, Style/IfUnlessModifier
  # rubocop:enable Lint/UnusedBlockArgument, Layout/LineLength
end
