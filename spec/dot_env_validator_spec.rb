require "spec_helper"

RSpec.describe DotenvValidator do
  let(:sample_lines) { StringIO.new("") }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(STDOUT).to receive(:puts) # this supresses puts
  end

  describe ".check" do
    before do
      allow(DotenvValidator).to receive(:open_sample_file).and_return(sample_lines)
    end

    context "when there are no variables" do
      it "returns true" do
        expect(DotenvValidator.check).to be_truthy
      end
    end

    context "when there is a variable that is required" do
      let(:sample_lines) do
        StringIO.new("admin_password=super_secret # required")
      end

      context "and ENV has said variable" do
        it "returns true" do
          ClimateControl.modify admin_password: "solarwinds123" do
            expect(DotenvValidator.check).to be_truthy
          end
        end
      end

      context "and ENV does not have said variable" do
        it "returns false" do
          expect(DotenvValidator.check).to be_falsey
        end

        it "displays a warning message in STDOUT" do
          msg = "WARNING - Missing environment variables: admin_password\n"
          expect do
            DotenvValidator.check
          end.to output(msg).to_stdout
        end
      end
    end

    context "when there is a variable that is optional" do
      context "and ENV does not have said variable" do
        let(:sample_lines) { StringIO.new("DISCOUNT=20") }

        it "returns true" do
          expect(DotenvValidator.check).to be_truthy
        end
      end

      context "and there is a string format parameter in the comment" do
        # anything counts as a string, since env variables are all strings by default
        let(:sample_lines) { StringIO.new("NAME=20 # format=string") }

        context "and ENV variable is a string" do
          it "returns true" do
            ClimateControl.modify NAME: "something" do
              expect(DotenvValidator.check).to be_truthy
            end
          end
        end
      end

      context "and there is an integer format parameter in the comment" do
        let(:sample_lines) { StringIO.new("DISCOUNT=20 # format=integer") }

        context "and ENV variable is an integer" do
          it "returns true" do
            ClimateControl.modify DISCOUNT: "42" do
              expect(DotenvValidator.check).to be_truthy
            end
          end
        end

        context "and ENV variable is not an integer" do
          it "returns false" do
            ClimateControl.modify DISCOUNT: "twenty" do
              expect(DotenvValidator.check).to be_falsey
            end
          end

          it "displays a warning message in STDOUT" do
            msg = "WARNING - Environment variables with invalid format: DISCOUNT\n"

            ClimateControl.modify DISCOUNT: "twenty" do
              expect do
                DotenvValidator.check
              end.to output(msg).to_stdout
            end
          end
        end
      end

      context "and there is an url format parameter in the comment" do
        let(:sample_lines) { StringIO.new("DISCOUNT_URL=http://google.com # format=url") }

        context "and ENV variable is an url" do
          it "returns true" do
            ClimateControl.modify DISCOUNT_URL: "https://fastruby.io" do
              expect(DotenvValidator.check).to be_truthy
            end
          end
        end

        context "and ENV variable is not an url" do
          it "returns false" do
            ClimateControl.modify DISCOUNT_URL: "foo/bar" do
              expect(DotenvValidator.check).to be_falsey
            end
          end

          it "displays a warning message in STDOUT" do
            msg = "WARNING - Environment variables with invalid format: DISCOUNT_URL\n"

            ClimateControl.modify DISCOUNT_URL: "foo/bar" do
              expect do
                DotenvValidator.check
              end.to output(msg).to_stdout
            end
          end
        end
      end

      context "and there is a boolean format parameter in the comment" do
        let(:sample_lines) { StringIO.new("MAYBE=true # format=boolean") }

        context "and ENV variable is a boolean" do
          it "returns true" do
            ClimateControl.modify MAYBE: "false" do
              expect(DotenvValidator.check).to be_truthy
            end
          end
        end

        context "and ENV variable is not a boolean" do
          it "returns false" do
            ClimateControl.modify MAYBE: "possibly" do
              expect(DotenvValidator.check).to be_falsy
            end
          end
        end

        it "displays a warning message in STDOUT" do
          msg = "WARNING - Environment variables with invalid format: MAYBE\n"

          ClimateControl.modify MAYBE: "possibly" do
            expect do
              DotenvValidator.check
            end.to output(msg).to_stdout
          end
        end
      end

      context "and there is a regexp format parameter in the comment" do
        let(:sample_lines) { StringIO.new('KEY_ID=123_ABC # format=\d{3}_\w{3}') }

        context "and ENV variable matches regexp" do
          it "returns true" do
            ClimateControl.modify KEY_ID: "567_FOO" do
              expect(DotenvValidator.check).to be_truthy
            end
          end
        end

        context "and ENV variable is not an url" do
          it "returns false" do
            ClimateControl.modify KEY_ID: "567_12" do
              expect(DotenvValidator.check).to be_falsey
            end
          end

          it "displays a warning message in STDOUT" do
            msg = "WARNING - Environment variables with invalid format: KEY_ID\n"

            ClimateControl.modify KEY_ID: "567_88" do
              expect do
                DotenvValidator.check
              end.to output(msg).to_stdout
            end
          end
        end
      end
    end
  end

  describe ".check!" do
    before do
      allow(DotenvValidator).to receive(:open_sample_file).and_return(sample_lines)
    end

    context "when there are no variables" do
      it "does not raise an error" do
        expect do
          DotenvValidator.check!
        end.not_to raise_error
      end
    end

    context "when there is a variable that is required" do
      let(:sample_lines) do
        StringIO.new("admin_password=super_secret # required")
      end

      context "and ENV has said variable" do
        it "does not raise an error" do
          ClimateControl.modify admin_password: "solarwinds123" do
            expect do
              DotenvValidator.check!
            end.not_to raise_error
          end
        end
      end

      context "and ENV does not have said variable" do
        it "raises a runtime error with a message" do
          msg = "Missing environment variables: admin_password"
          expect do
            DotenvValidator.check!
          end.to raise_error(RuntimeError, msg)
        end
      end
    end

    context "when there is a variable that is optional" do
      context "and ENV does not have said variable" do
        let(:sample_lines) { StringIO.new("DISCOUNT=20") }

        it "does not raise an error" do
          expect do
            DotenvValidator.check!
          end.not_to raise_error
        end
      end

      context "and there is an integer format parameter in the comment" do
        let(:sample_lines) { StringIO.new("DISCOUNT=20 # format=integer") }

        context "and ENV variable is an integer" do
          it "does not raise a runtime error" do
            ClimateControl.modify DISCOUNT: "42" do
              expect do
                DotenvValidator.check!
              end.not_to raise_error
            end
          end
        end

        context "and ENV variable is not an integer" do
          it "raises a runtime error with a warning message" do
            msg = "Environment variables with invalid format: DISCOUNT"

            ClimateControl.modify DISCOUNT: "twenty" do
              expect do
                DotenvValidator.check!
              end.to raise_error(RuntimeError, msg)
            end
          end
        end
      end

      context "and there is a boolean format parameter in the comment" do
        let(:sample_lines) { StringIO.new("MAYBE=true # format=boolean") }

        context "and ENV variable is a boolean" do
          it "does not raise a runtime error" do
            ClimateControl.modify MAYBE: "false" do
              expect do
                DotenvValidator.check!
              end.not_to raise_error
            end
          end
        end

        context "and ENV variable is not a boolean" do
          it "raises a runtime error with a warning message" do
            msg = "Environment variables with invalid format: MAYBE"

            ClimateControl.modify MAYBE: "possibly" do
              expect do
                DotenvValidator.check!
              end.to raise_error(RuntimeError, msg)
            end
          end
        end
      end
    end
  end

  describe ".open_sample_file" do
    context "when sample file exists" do
      it "opens the file" do
        ClimateControl.modify RAILS_ROOT: "spec/support" do
          expect(DotenvValidator.open_sample_file).to be_truthy
        end
      end
    end

    context "when sample file does not exist" do
      let(:message) do
        "spec/support/not_found/.env.sample was not found!"
      end

      it "raises an error because it requires this file to validate ENV" do
        ClimateControl.modify RAILS_ROOT: "spec/support/not_found" do
          expect do
            DotenvValidator.open_sample_file
          end.to raise_error(DotenvValidator::SampleFileNotFoundError, message)
        end
      end
    end
  end
end
