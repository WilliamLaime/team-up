require "test_helper"

# Tests du Checker — l'orchestrateur central de la modération. On injecte un
# fake adapter via une sous-classe qui override `adapter` pour isoler
# complètement ces tests de l'API Sightengine (pas de gem de mocking requise).
class ImageModeration::CheckerTest < ActiveSupport::TestCase
  setup do
    @user   = users(:one)
    @profil = profils(:one)

    # Attache un vrai fichier PNG pour que blob.download retourne des bytes.
    @profil.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "test.png",
      content_type: "image/png"
    )

    # Nettoie d'éventuelles lignes de modération d'un run précédent.
    ImageModeration.where(moderatable: @profil, attachment_name: "avatar").destroy_all
  end

  teardown do
    Thread.current[ImageModeration::Checker::THREAD_SKIP_KEY] = false
    ImageModeration.where(moderatable: @profil, attachment_name: "avatar").destroy_all
    @profil.avatar.purge if @profil.reload.avatar.attached?
  end

  # ── Verdict safe ──────────────────────────────────────────────────────────

  test "image safe crée une ligne approved et garde l'attachement" do
    call_checker(score: 0.01)

    mod = moderation_for_profil
    assert_equal "approved", mod.status
    assert_in_delta 0.01, mod.score
    assert_equal "safe", mod.reason
    assert_equal "fake_adapter", mod.provider
    assert mod.checked_at.present?
    assert @profil.reload.avatar.attached?
  end

  # ── Verdict NSFW ──────────────────────────────────────────────────────────

  test "image NSFW crée une ligne rejected" do
    call_checker(score: 0.95)

    mod = moderation_for_profil
    assert_equal "rejected", mod.status
    assert_in_delta 0.95, mod.score
    assert_equal "nsfw_detected", mod.reason
  end

  test "image NSFW crée une notification pour l'owner" do
    assert_difference -> { Notification.where(user: @user, notif_type: "image_rejected").count }, 1 do
      call_checker(score: 0.95)
    end

    notif = Notification.where(user: @user, notif_type: "image_rejected").last
    assert notif.message.include?("photo de profil")
  end

  test "image NSFW pose le flag THREAD_SKIP_KEY pendant la purge" do
    flag_values_during_purge = []

    # On monkey-patch purge_later pour capturer le flag au moment exact de la
    # purge. On n'a besoin de rien d'autre — le comportement du Checker n'est
    # pas altéré puisqu'on ne change pas le retour.
    @profil.avatar.define_singleton_method(:purge_later) do
      flag_values_during_purge << Thread.current[ImageModeration::Checker::THREAD_SKIP_KEY]
    end

    call_checker(score: 0.95)

    assert_equal [true], flag_values_during_purge
    refute Thread.current[ImageModeration::Checker::THREAD_SKIP_KEY]
  end

  # ── Pas d'attachement ────────────────────────────────────────────────────

  test "sans attachement, le checker quitte silencieusement" do
    @profil.avatar.purge

    assert_no_difference -> { ImageModeration.count } do
      call_checker(score: 0.01)
    end
  end

  # ── Quota local épuisé ────────────────────────────────────────────────────

  test "quota local épuisé crée une ligne errored sans appeler l'API" do
    # Simule un quota dépassé en définissant temporairement une méthode de
    # classe qui retourne la valeur max. Plus léger qu'une gem de mocking.
    original = ImageModeration.method(:quota_used_this_month)
    ImageModeration.define_singleton_method(:quota_used_this_month) { ImageModeration::MONTHLY_QUOTA }

    call_checker(score: 0.01)

    mod = moderation_for_profil
    assert_equal "errored", mod.status
    assert_equal "quota_exceeded_local", mod.reason
    assert_nil mod.score
  ensure
    ImageModeration.define_singleton_method(:quota_used_this_month, original)
  end

  # ── QuotaExceededError ────────────────────────────────────────────────────

  test "QuotaExceededError crée une ligne errored" do
    call_checker(exception: ImageModeration::QuotaExceededError.new("limit hit"))

    mod = moderation_for_profil
    assert_equal "errored", mod.status
    assert_equal "quota_exceeded", mod.reason
  end

  # ── ApiError / RateLimitError ─────────────────────────────────────────────

  test "ApiError remonte l'exception pour que le Job la retry" do
    assert_raises(ImageModeration::ApiError) do
      call_checker(exception: ImageModeration::ApiError.new("500 error"))
    end
  end

  test "RateLimitError remonte l'exception pour que le Job la retry" do
    assert_raises(ImageModeration::RateLimitError) do
      call_checker(exception: ImageModeration::RateLimitError.new("429"))
    end
  end

  # ── Idempotence ───────────────────────────────────────────────────────────

  test "un second appel met à jour la ligne existante au lieu d'en créer une nouvelle" do
    call_checker(score: 0.01)

    assert_no_difference -> { ImageModeration.count } do
      call_checker(score: 0.5)
    end

    mod = moderation_for_profil
    assert_in_delta 0.5, mod.score
  end

  private

  # Appelle le Checker avec un fake adapter injecté via sous-classe.
  def call_checker(score: nil, exception: nil)
    fake_adapter = FakeAdapter.new(score: score, exception: exception)
    checker = TestableChecker.new(@profil, :avatar, fake_adapter)
    checker.call
  end

  def moderation_for_profil
    ImageModeration.find_by!(moderatable: @profil, attachment_name: "avatar")
  end

  # Sous-classe du Checker qui accepte un adapter injecté au constructeur.
  # On n'a besoin de rien d'autre qu'un override de `adapter`.
  class TestableChecker < ImageModeration::Checker
    def initialize(record, attachment_name, fake_adapter)
      super(record, attachment_name)
      @fake_adapter = fake_adapter
    end

    private

    def adapter
      @fake_adapter
    end
  end

  # Adapter minimal qui retourne un Result pré-configuré ou lève une exception.
  class FakeAdapter < ImageModeration::Adapters::Base
    def initialize(score: nil, exception: nil)
      super()
      @score     = score
      @exception = exception
    end

    def analyze(_io, filename:)
      raise @exception if @exception
      ImageModeration::Result.new(score: @score || 0.0)
    end

    def provider_name
      "fake_adapter"
    end
  end
end
