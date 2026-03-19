# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# ── Sports de base ────────────────────────────────────────────────────────────
# find_or_create_by! = idempotent (peut être relancé sans créer de doublons)
puts "Création des sports..."

sports_data = [
  { name: "Football",   icon: "⚽", slug: "football"   },
  { name: "Tennis",     icon: "🎾", slug: "tennis"     },
  { name: "Padel",      icon: "sports/padel.png", slug: "padel"      },
  { name: "Volleyball", icon: "🏐", slug: "volleyball" },
  { name: "Basketball", icon: "🏀", slug: "basketball" },
  { name: "Handball",   icon: "🤾", slug: "handball"   },
  { name: "Badminton",  icon: "🏸", slug: "badminton"  }
]

sports_data.each do |sport|
  Sport.find_or_create_by!(slug: sport[:slug]) do |s|
    s.name = sport[:name]
    s.icon = sport[:icon]
  end
end

puts "✅ #{Sport.count} sports créés."

# ── Avis de test ──────────────────────────────────────────────────────────────
# Crée quelques avis fictifs entre les 2 premiers users + leur premier match commun
# Seulement si les conditions sont réunies (users existants, match passé commun)
puts "Création des avis de test..."

# Récupère les 3 premiers users ayant un profil
users_with_profil = User.joins(:profil).limit(3).to_a

if users_with_profil.size >= 2
  # Cherche un match terminé (date dans le passé) avec au moins 2 joueurs approuvés
  completed_match = Match
    .joins(:match_users)
    .where(match_users: { status: "approved" })
    .where("(matches.date + matches.time) < ?", Time.current - 1.hour)
    .group("matches.id")
    .having("COUNT(match_users.id) >= 2")
    .first

  if completed_match
    # Récupère les 2 premiers participants approuvés de ce match
    participants = completed_match.match_users
                                  .where(status: "approved")
                                  .includes(:user)
                                  .limit(2)
                                  .map(&:user)

    if participants.size >= 2
      user_a = participants[0]
      user_b = participants[1]

      # Avis de A vers B
      Avis.find_or_create_by!(
        reviewer:      user_a,
        reviewed_user: user_b,
        match:         completed_match
      ) do |a|
        a.rating  = 5
        a.content = "Super joueur, ponctuel et fair-play. Je recommande !"
      end

      # Avis de B vers A
      Avis.find_or_create_by!(
        reviewer:      user_b,
        reviewed_user: user_a,
        match:         completed_match
      ) do |a|
        a.rating  = 4
        a.content = "Bonne technique, bon esprit d'équipe."
      end

      puts "✅ #{Avis.count} avis de test créés (match : #{completed_match.title})."
    else
      puts "⚠️  Pas assez de participants approuvés dans le match trouvé."
    end
  else
    puts "⚠️  Aucun match terminé trouvé pour créer les avis de test."
  end
else
  puts "⚠️  Pas assez d'utilisateurs avec profil pour créer les avis de test."
end
