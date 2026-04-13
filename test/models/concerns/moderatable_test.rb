require "test_helper"

# Tests du concern Moderatable, intégré via Profil (1 attachement) et Team
# (2 attachements). On teste le cycle de vie complet des callbacks :
#   - upload → job enfilé
#   - update sans changement d'image → pas de job
#   - purge volontaire → pas de job
#   - flag THREAD_SKIP_KEY → pas de job
#   - Team avec 2 images → 2 jobs
class ModeratableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user   = users(:one)
    @profil = profils(:one)

    # On utilise le queue adapter :test pour inspecter les jobs enfilés
    # sans les exécuter (pas d'appel API réel).
    @old_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter = @old_adapter
    Thread.current[ImageModeration::Checker::THREAD_SKIP_KEY] = false
    @profil.avatar.purge if @profil.reload.avatar.attached?
  end

  # ── Profil : upload d'un avatar ───────────────────────────────────────────

  test "attacher un avatar sur Profil enfile un ModerateImageJob" do
    assert_enqueued_with(job: ModerateImageJob) do
      attach_sample_image(@profil, :avatar)
    end
  end

  test "modifier le profil sans changer l'avatar n'enfile pas de job" do
    attach_sample_image(@profil, :avatar)
    clear_enqueued_jobs

    assert_no_enqueued_jobs(only: ModerateImageJob) do
      @profil.update!(preferred_city: "Lyon")
    end
  end

  test "purge volontaire de l'avatar n'enfile pas de ModerateImageJob" do
    attach_sample_image(@profil, :avatar)
    clear_enqueued_jobs

    @profil.avatar.purge

    assert_no_enqueued_jobs(only: ModerateImageJob)
  end

  test "le flag THREAD_SKIP_KEY empêche l'enfilement du job" do
    Thread.current[ImageModeration::Checker::THREAD_SKIP_KEY] = true

    assert_no_enqueued_jobs(only: ModerateImageJob) do
      attach_sample_image(@profil, :avatar)
    end
  end

  test "remplacer un avatar existant enfile un nouveau job" do
    attach_sample_image(@profil, :avatar)
    clear_enqueued_jobs

    assert_enqueued_with(job: ModerateImageJob) do
      attach_sample_image(@profil, :avatar, filename: "new_avatar.png")
    end
  end

  # ── Team : deux attachements modérés ──────────────────────────────────────

  test "attacher badge_image et cover_image sur Team enfile deux jobs" do
    team = Team.create!(name: "Test FC", captain: @user)

    assert_enqueued_jobs 2, only: ModerateImageJob do
      team.badge_image.attach(
        io: File.open(sample_image_path),
        filename: "badge.png",
        content_type: "image/png"
      )
      team.cover_image.attach(
        io: File.open(sample_image_path),
        filename: "cover.png",
        content_type: "image/png"
      )
    end
  ensure
    team&.destroy
  end

  # ── DSL ───────────────────────────────────────────────────────────────────

  test "Profil déclare avatar comme attachement modéré" do
    assert_equal ["avatar"], Profil._moderated_attachment_names
  end

  test "Team déclare badge_image et cover_image comme attachements modérés" do
    assert_equal ["badge_image", "cover_image"], Team._moderated_attachment_names
  end

  private

  def sample_image_path
    Rails.root.join("test/fixtures/files/sample.png")
  end

  def attach_sample_image(record, attachment_name, filename: "sample.png")
    record.public_send(attachment_name).attach(
      io: File.open(sample_image_path),
      filename: filename,
      content_type: "image/png"
    )
  end
end
