describe RemoteRuby::SourceExtractor do
  subject { described_class.new }

  let(:desired_result) do
<<-RUBY.strip
a.foo1
foo2
foo3(bar)
x = 3
if (x == 4)
  y = 5
end
unless y
  return
end
RUBY
  end

  context 'with do-block' do
    context 'well-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract do
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            return unless y
          end

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          res = subject.extract do |context, a, b|
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            unless y
              return
            end
          end

          expect(res).to eq(desired_result)
        end
      end
    end

    context 'ill-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract do a.foo1; foo2; foo3(bar); x=3
            y=5 if x ==4
            return unless y
          end

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          res = subject.extract do |context, a, b| a.foo1; foo2; foo3(bar); x=3
            y=5 if x ==4
            return unless y
          end

          expect(res).to eq(desired_result)
        end
      end
    end
  end

  context 'with {}-block' do
    context 'well-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract { a.foo1; foo2; foo3(bar); x=3; y = 5 if x == 4; return unless y }

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          res = subject.extract { |context, a, b| a.foo1; foo2; foo3(bar); x=3; y = 5 if x == 4; return unless y }

          expect(res).to eq(desired_result)
        end
      end
    end

    context 'ill-formatted' do
      context 'without arguments' do
        it 'returns correct value' do
          res = subject.extract {
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            return unless y
          }

          expect(res).to eq(desired_result)
        end
      end

      context 'with arguments' do
        it 'returns correct value' do
          res = subject.extract { |context, a, b|
            a.foo1
            foo2
            foo3(bar)
            x = 3

            if x == 4
              y = 5
            end

            return unless y
            }

          expect(res).to eq(desired_result)
        end
      end
    end
  end
end
