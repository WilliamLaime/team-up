require "test_helper"

# Tests du value object qui porte le verdict d'un adapter. La logique est
# minimaliste mais on verrouille ici le contrat du seuil — si quelqu'un
# change NSFW_THRESHOLD par erreur, ces tests sautent immédiatement.
class ImageModeration::ResultTest < ActiveSupport::TestCase
  test "score en dessous du seuil est safe" do
    result = ImageModeration::Result.new(score: 0.1)
    assert_equal :safe, result.label
    refute result.nsfw?
  end

  test "score au dessus du seuil est nsfw" do
    result = ImageModeration::Result.new(score: 0.95)
    assert_equal :nsfw, result.label
    assert result.nsfw?
  end

  test "score pile sur le seuil est nsfw (inclusif)" do
    # Le seuil est inclusif : >= NSFW_THRESHOLD → nsfw.
    # On lock cette décision ici pour que personne ne la flip par inadvertance.
    result = ImageModeration::Result.new(score: ImageModeration::NSFW_THRESHOLD)
    assert result.nsfw?
  end

  test "score 0.0 est safe" do
    result = ImageModeration::Result.new(score: 0.0)
    refute result.nsfw?
  end

  test "score cast en Float" do
    # Le score peut arriver sous forme de String depuis un JSON mal typé.
    result = ImageModeration::Result.new(score: "0.5")
    assert_in_delta 0.5, result.score
  end

  test "raw hash est conservé tel quel" do
    raw = { "nudity" => { "sexual_activity" => 0.01 }, "status" => "success" }
    result = ImageModeration::Result.new(score: 0.01, raw: raw)
    assert_equal raw, result.raw
  end

  test "raw défaut à hash vide" do
    result = ImageModeration::Result.new(score: 0.2)
    assert_equal({}, result.raw)
  end
end
