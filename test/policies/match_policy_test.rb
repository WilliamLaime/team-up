require "test_helper"

class MatchPolicyTest < ActiveSupport::TestCase
  # On crée deux utilisateurs : le créateur du match et un autre utilisateur
  def setup
    @owner = users(:one)    # utilisateur qui a créé le match
    @other = users(:two)    # autre utilisateur
    @match = matches(:one)  # un match appartenant à @owner
  end

  # Tout le monde peut créer un match
  def test_create
    assert MatchPolicy.new(@owner, @match).create?
    assert MatchPolicy.new(@other, @match).create?
  end

  # Tout le monde peut voir un match
  def test_show
    assert MatchPolicy.new(@owner, @match).show?
    assert MatchPolicy.new(@other, @match).show?
  end

  # Seul le créateur peut modifier un match
  def test_update
    assert MatchPolicy.new(@owner, @match).update?
    refute MatchPolicy.new(@other, @match).update?
  end

  # Seul le créateur peut supprimer un match
  def test_destroy
    assert MatchPolicy.new(@owner, @match).destroy?
    refute MatchPolicy.new(@other, @match).destroy?
  end

  # Le scope retourne tous les matchs pour n'importe quel utilisateur
  def test_scope
    all_matches = Match.all
    resolved = MatchPolicy::Scope.new(@owner, Match.all).resolve
    assert_equal all_matches.count, resolved.count
  end
end
