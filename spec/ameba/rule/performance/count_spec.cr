require "../../../spec_helper"

module Ameba::Rule::Performance
  subject = Count.new

  describe Count do
    it "passes if there is no potential performance improvements" do
      source = Source.new %(
        [1, 2, 3].select { |e| e > 2 }
        [1, 2, 3].reject { |e| e < 2 }
        [1, 2, 3].count { |e| e > 2 && e.odd? }
        [1, 2, 3].count { |e| e < 2 && e.even? }

        User.select("field AS name").count
        Company.select(:value).count
      )
      subject.catch(source).should be_valid
    end

    it "reports if there is a select followed by size" do
      source = Source.new %(
        [1, 2, 3].select { |e| e > 2 }.size
      )
      subject.catch(source).should_not be_valid
    end

    it "reports if there is a reject followed by size" do
      source = Source.new %(
        [1, 2, 3].reject { |e| e < 2 }.size
      )
      subject.catch(source).should_not be_valid
    end

    it "reports if a block shorthand used" do
      source = Source.new %(
        [1, 2, 3].reject(&.empty?).size
      )
      subject.catch(source).should_not be_valid
    end

    context "properties" do
      it "allows to configure object caller names" do
        source = Source.new %(
          [1, 2, 3].reject(&.empty?).size
        )
        rule = Rule::Performance::Count.new
        rule.object_call_names = %w(select)
        rule.catch(source).should be_valid
      end
    end

    it "reports rule, pos and message" do
      s = Source.new %(
        File.read(path)
          .split("\n")
          .reject(&.empty?)
          .size
      ), "source.cr"
      subject.catch(s).should_not be_valid
      issue = s.issues.first

      issue.rule.should_not be_nil
      issue.location.to_s.should eq "source.cr:2:9"
      issue.message.should eq "Use `count {...}` instead of `reject {...}.size`."
    end
  end
end
