require 'spec_helper'

describe Rugments::Lexer do
  lexer = Rugments::Lexer.find_by_name('ruby')
  lexers = Rugments::Lexer.all

  describe '.all' do
    it 'returns an array of all lexer classes' do
      expect(lexers).to be_an_instance_of(Array)
      expect(lexers.first).to be_an_instance_of(Class)
    end
  end

  describe '.find_by_name' do
    it 'returns specifix lexer class' do
      expect(lexer.new).to be_an_instance_of(Rugments::Lexers::Ruby)
    end
  end

  describe '.tag' do
    it 'returns the unique identifier' do
      expect(lexer.tag.to_s).to eq('ruby')
    end
  end

  describe '.title' do
    it 'returns the human readable title' do
      expect(lexer.title).to eq('Ruby')
    end
  end

  describe '.desc' do
    it 'returns the human readable description' do
      expect(lexer.desc).to eq('The Ruby programming language (ruby-lang.org)')
    end
  end

  describe '.aliases' do
    it 'returns the aliases array' do
      expect(lexer.aliases).to eq(%w(rb))
    end
  end

  describe '.filenames' do
    it 'returns the filenames array' do
      expect(lexer.filenames).to eq(
        %w(*.rb *.ruby *.rbw *.rake *.gemspec *.podspec Rakefile Guardfile
           Gemfile Capfile Podfile Vagrantfile *.ru *.prawn)
      )
    end
  end

  describe '.mimetypes' do
    it 'returns the mimetypes array' do
      expect(lexer.mimetypes).to eq(%w(text/x-ruby application/x-ruby))
    end
  end

  describe 'guess_for_filename' do
    it 'returns a lexer which matches the filename pattern' do
      lexer = Rugments::Lexer.guess_for_filename('test.rb', '')
      expect(lexer.new).to be_an_instance_of(Rugments::Lexers::Ruby)
    end
  end
end
