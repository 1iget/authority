require 'spec_helper'
require 'support/example_classes'

describe Authority::UserAbilities do

  let(:resource_instance) { ExampleResource.new }
  let(:user)              { ExampleUser.new }

  describe "using `can_{verb}?` methods to check permissions on a resource" do

    Authority.verbs.each do |verb|
      method_name = "can_#{verb}?"

      it "defines the `#{method_name}` method" do
        expect(user).to respond_to(method_name)
      end

      describe "if given options" do

        it "delegates the authorization check to the resource, passing the options" do
          resource_instance.should_receive("#{Authority.abilities[verb]}_by?").with(user, :size => 'wee')
          user.send(method_name, resource_instance, :size => 'wee')
        end

      end

      describe "if not given options" do

        it "delegates the authorization check to the resource, passing no options" do
          resource_instance.should_receive("#{Authority.abilities[verb]}_by?").with(user)
          user.send(method_name, resource_instance)
        end

      end

    end

  end

  describe "using `can?` for non-resource-specific checks" do

    context "when ApplicationAuthorizer responds to a matching `authorizes_to?` call" do

      before :each do
        ApplicationAuthorizer.stub(:authorizes_to_mimic_lemurs?).and_return('yessir')
      end

      it "uses the `authorizes_to` return value" do
        expect(user.can?(:mimic_lemurs)).to eq('yessir')
      end

    end

    context "when ApplicationAuthorizer does not respond to a matching `authorizes_to?` call" do

      before :each do
        ApplicationAuthorizer.stub(:authorizes_to_mimic_lemurs?).and_raise(NoMethodError.new('eh?'))
      end

      context "when ApplicationAuthorizer responds to a matching `can` call" do

        before :each do
          ApplicationAuthorizer.stub(:can_mimic_lemurs?).and_return('thumbs up!')
          # NOTE - prevents annoying output during these tests, but don't try to use `puts` below... ;)
          $stdout.stub(:puts) 
        end

        it "uses the `can` return value (for backwards compatibility)" do
          expect(user.can?(:mimic_lemurs)).to eq('thumbs up!')
        end

        it "puts a deprecation warning" do
          $stdout.should_receive(:puts).with(
            "DEPRECATION WARNING: Please rename `ApplicationAuthorizer.can_mimic_lemurs?` to `authorizes_to_mimic_lemurs?`"
          )
          user.can?(:mimic_lemurs)
        end

      end

      context "when ApplicationAuthorizer does not respond to a matching `can` call" do

        before(:each) do
          ApplicationAuthorizer.stub(:can_mimic_lemurs?).and_raise(NoMethodError.new('whaaa?'))
        end

        it "re-raises the NoMethodError from the missing `authorizes_to?`" do
          expect{user.can?(:mimic_lemurs)}.to raise_error(NoMethodError, 'eh?')
        end

      end

    end

  end

end
