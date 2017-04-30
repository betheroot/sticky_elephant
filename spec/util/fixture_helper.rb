require 'pathname'

module FixtureHelper
  def fixture_dir
    Pathname(spec_dir.join('fixtures'))
  end

  def spec_dir
    Pathname(RSpec::Core::RubyProject.root).join('spec')
  end

  def fixture(pn)
    pathname = Pathname(pn)
    File.read(fixture_dir.join(pathname)).bytes
  end
end
