require 'spec_helper'
require 'email/receiver'

describe Email::Receiver do

  before do
    SiteSetting.stubs(:reply_by_email_address).returns("reply+%{reply_key}@appmail.adventuretime.ooo")
  end

  describe 'invalid emails' do
    it "returns unprocessable if the message is blank" do
      expect(Email::Receiver.new("").process).to eq(Email::Receiver.results[:unprocessable])
    end

    it "returns unprocessable if the message is not an email" do
      expect(Email::Receiver.new("asdf" * 30).process).to eq(Email::Receiver.results[:unprocessable])
    end
  end

  describe "with a valid email" do
    let(:reply_key) { "59d8df8370b7e95c5a49fbf86aeb2c93" }
    let(:valid_reply) { File.read("#{Rails.root}/spec/fixtures/emails/valid_reply.txt") }
    let(:receiver) { Email::Receiver.new(valid_reply) }
    let(:post) { Fabricate.build(:post) }
    let(:user) { Fabricate.build(:user) }
    let(:email_log) { EmailLog.new(reply_key: reply_key, post_id: 1234, topic_id: 4567, user_id: 6677, post: post, user: user ) }
    let(:reply_body) {
"I could not disagree more. I am obviously biased but adventure time is the
greatest show ever created. Everyone should watch it.

- Jake out" }

    describe "email with non-existant email log" do

      before do
        EmailLog.expects(:for).returns(nil)
      end

      let!(:result) { receiver.process }

      it "returns missing" do
        expect(result).to eq(Email::Receiver.results[:missing])
      end

    end

    describe "with an email log" do

      before do
        EmailLog.expects(:for).with(reply_key).returns(email_log)

        creator = mock
        PostCreator.expects(:new).with(instance_of(User), has_entry(raw: reply_body)).returns(creator)
        creator.expects(:create)
      end

      let!(:result) { receiver.process }

      it "returns a processed result" do
        expect(result).to eq(Email::Receiver.results[:processed])
      end

      it "extracts the body" do
        expect(receiver.body).to eq(reply_body)
      end

      it "looks up the email log" do
        expect(receiver.email_log).to eq(email_log)
      end

      it "extracts the key" do
        expect(receiver.reply_key).to eq(reply_key)
      end

    end

  end


end
