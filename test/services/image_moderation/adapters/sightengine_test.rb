require "test_helper"
require "webmock/minitest"

# Tests de l'adapter Sightengine. On stub toutes les requêtes HTTP pour ne
# jamais appeler l'API réelle en test (pas de consommation de quota, pas de
# flakiness réseau). WebMock intercepte net/http de façon transparente.
class ImageModeration::Adapters::SightengineTest < ActiveSupport::TestCase
  setup do
    @adapter = ImageModeration::Adapters::Sightengine.new(
      api_user:   "fake_user",
      api_secret: "fake_secret"
    )
    @io       = StringIO.new("fake image bytes")
    @filename = "avatar.jpg"
  end

  # ── Réponse 200 OK ────────────────────────────────────────────────────────

  test "réponse safe retourne un Result avec score bas" do
    stub_sightengine_success(sexual_activity: 0.001, sexual_display: 0.002, erotica: 0.001, very_suggestive: 0.003)

    result = @adapter.analyze(@io, filename: @filename)

    assert_instance_of ImageModeration::Result, result
    assert_in_delta 0.003, result.score
    refute result.nsfw?
  end

  test "réponse NSFW retourne un Result avec score élevé" do
    stub_sightengine_success(sexual_activity: 0.92, sexual_display: 0.01, erotica: 0.05, very_suggestive: 0.10)

    result = @adapter.analyze(@io, filename: @filename)

    assert_in_delta 0.92, result.score
    assert result.nsfw?
  end

  test "les catégories suggestive (bikini, cleavage) sont ignorées" do
    # Score explicite bas mais suggestive_classes élevé — le score ne doit
    # PAS monter puisqu'on ignore ces catégories (contexte sportif).
    stub_sightengine_success(
      sexual_activity: 0.01, sexual_display: 0.01,
      erotica: 0.01, very_suggestive: 0.01,
      extra: { "bikini" => 0.95, "cleavage" => 0.90, "male_chest" => 0.99 }
    )

    result = @adapter.analyze(@io, filename: @filename)

    assert_in_delta 0.01, result.score
    refute result.nsfw?
  end

  test "raw hash est conservé dans le Result" do
    stub_sightengine_success(sexual_activity: 0.001, sexual_display: 0.001, erotica: 0.001, very_suggestive: 0.001)

    result = @adapter.analyze(@io, filename: @filename)

    assert_equal "success", result.raw["status"]
    assert result.raw.key?("nudity")
  end

  # ── Erreurs HTTP ──────────────────────────────────────────────────────────

  test "HTTP 429 lève RateLimitError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 429, body: '{"error": {"type": "rate_limit"}}')

    assert_raises(ImageModeration::RateLimitError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  test "HTTP 400 avec usage_limit lève QuotaExceededError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 400, body: '{"error": {"type": "usage_limit"}}')

    assert_raises(ImageModeration::QuotaExceededError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  test "HTTP 400 avec monthly_limit lève QuotaExceededError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 400, body: '{"error": {"type": "monthly_limit"}}')

    assert_raises(ImageModeration::QuotaExceededError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  test "HTTP 400 avec autre erreur lève ApiError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 400, body: '{"error": {"type": "invalid_request"}}')

    assert_raises(ImageModeration::ApiError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  test "HTTP 500 lève ApiError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 500, body: "Internal Server Error")

    assert_raises(ImageModeration::ApiError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  # ── Erreurs réseau ────────────────────────────────────────────────────────

  test "timeout réseau lève ApiError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_timeout

    assert_raises(ImageModeration::ApiError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  test "erreur de connexion lève ApiError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_raise(Errno::ECONNRESET)

    assert_raises(ImageModeration::ApiError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  # ── Réponse 200 mais JSON invalide ────────────────────────────────────────

  test "JSON invalide en 200 lève ApiError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 200, body: "not json at all")

    assert_raises(ImageModeration::ApiError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  test "JSON 200 sans nudity hash lève ApiError" do
    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 200, body: '{"status": "success", "weapon": {}}')

    assert_raises(ImageModeration::ApiError) do
      @adapter.analyze(@io, filename: @filename)
    end
  end

  # ── Provider name ─────────────────────────────────────────────────────────

  test "provider_name retourne sightengine" do
    assert_equal "sightengine", @adapter.provider_name
  end

  private

  # Helper pour stubber une réponse 200 de Sightengine avec les scores voulus.
  # Les clés non fournies valent 0.001 par défaut (comportement réaliste).
  def stub_sightengine_success(sexual_activity: 0.001, sexual_display: 0.001, erotica: 0.001, very_suggestive: 0.001, extra: {})
    nudity = {
      "sexual_activity" => sexual_activity,
      "sexual_display"  => sexual_display,
      "erotica"         => erotica,
      "very_suggestive" => very_suggestive
    }.merge(extra)

    body = { "status" => "success", "nudity" => nudity }.to_json

    stub_request(:post, "https://api.sightengine.com/1.0/check.json")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })
  end
end
