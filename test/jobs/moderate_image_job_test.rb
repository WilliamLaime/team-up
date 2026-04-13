require "test_helper"

# Tests du ModerateImageJob. On vérifie que le job :
#   1. Délègue correctement au Checker
#   2. S'enfile dans la bonne queue
#   3. Peut être enfilé via perform_later
class ModerateImageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @profil = profils(:one)
  end

  test "perform appelle le Checker avec le record et le nom d'attachement" do
    checker_called_with = nil

    original = ImageModeration::Checker.method(:call)
    ImageModeration::Checker.define_singleton_method(:call) do |record, attachment_name|
      checker_called_with = [record, attachment_name.to_s]
    end

    ModerateImageJob.perform_now(@profil, "avatar")

    assert_equal [@profil, "avatar"], checker_called_with
  ensure
    ImageModeration::Checker.define_singleton_method(:call, original)
  end

  test "le job est dans la queue default" do
    assert_equal "default", ModerateImageJob.new.queue_name
  end

  test "le job peut être enfilé avec perform_later" do
    assert_enqueued_with(job: ModerateImageJob, args: [@profil, "avatar"]) do
      ModerateImageJob.perform_later(@profil, "avatar")
    end
  end
end
