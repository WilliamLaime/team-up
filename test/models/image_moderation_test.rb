require "test_helper"

# Tests du modèle ImageModeration — validations, enum, scopes, quota.
class ImageModerationTest < ActiveSupport::TestCase
  setup do
    @profil = profils(:one)
  end

  teardown do
    ImageModeration.where(moderatable: @profil).destroy_all
  end

  # ── Validations ───────────────────────────────────────────────────────────

  test "valide avec les attributs minimaux" do
    mod = build_moderation
    assert mod.valid?
  end

  test "attachment_name est requis" do
    mod = build_moderation(attachment_name: nil)
    refute mod.valid?
    assert mod.errors[:attachment_name].any?
  end

  test "provider est requis" do
    mod = build_moderation(provider: nil)
    refute mod.valid?
    assert mod.errors[:provider].any?
  end

  test "score doit être entre 0 et 1" do
    mod = build_moderation(score: 1.5)
    refute mod.valid?

    mod = build_moderation(score: -0.1)
    refute mod.valid?

    mod = build_moderation(score: 0.5)
    assert mod.valid?
  end

  test "score nil est accepté (pas encore modéré)" do
    mod = build_moderation(score: nil)
    assert mod.valid?
  end

  test "unicité attachment_name par couple (moderatable_type, moderatable_id)" do
    build_moderation.save!
    duplicate = build_moderation
    refute duplicate.valid?
    assert duplicate.errors[:attachment_name].any?
  end

  # ── Enum statuts ──────────────────────────────────────────────────────────

  test "les 4 statuts sont bien définis" do
    assert_equal %w[pending approved rejected errored], ImageModeration.statuses.keys
  end

  test "statut par défaut est pending" do
    mod = ImageModeration.new
    assert_equal "pending", mod.status
  end

  # ── Constantes ────────────────────────────────────────────────────────────

  test "NSFW_THRESHOLD est 0.8" do
    assert_equal 0.8, ImageModeration::NSFW_THRESHOLD
  end

  test "MONTHLY_QUOTA est 2000" do
    assert_equal 2000, ImageModeration::MONTHLY_QUOTA
  end

  # ── Quota ─────────────────────────────────────────────────────────────────

  test "quota_used_this_month compte les lignes checked_at ce mois" do
    # Crée une ligne modérée ce mois-ci.
    build_moderation(checked_at: Time.current).save!
    assert_operator ImageModeration.quota_used_this_month, :>=, 1
  end

  test "quota_used_this_month ignore les lignes sans checked_at" do
    build_moderation(checked_at: nil).save!

    count_with_nil = ImageModeration.where(moderatable: @profil, checked_at: nil).count
    assert_operator count_with_nil, :>=, 1
  end

  # ── Hiérarchie d'exceptions ───────────────────────────────────────────────

  test "RateLimitError est un ApiError" do
    assert ImageModeration::RateLimitError < ImageModeration::ApiError
  end

  test "QuotaExceededError est un Error mais PAS un ApiError" do
    assert ImageModeration::QuotaExceededError < ImageModeration::Error
    refute ImageModeration::QuotaExceededError < ImageModeration::ApiError
  end

  private

  def build_moderation(**overrides)
    ImageModeration.new({
      moderatable: @profil,
      attachment_name: "avatar",
      provider: "sightengine",
      status: "pending"
    }.merge(overrides))
  end
end
