# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# ─── ACHIEVEMENTS ─────────────────────────────────────────────────────────────
# On utilise find_or_create_by! pour que ce seed soit idempotent
# (peut être relancé sans créer de doublons)

puts "Création des achievements..."

achievements_data = [
  # ── Catégorie MATCH ──────────────────────────────────────────────────────────
  {
    key:         "first_join",
    name:        "Premier pas sur le terrain",
    description: "Rejoins ton premier match",
    xp_reward:   50,
    icon_emoji:  "⚽",
    category:    "match"
  },
  {
    key:         "matches_5",
    name:        "Habitué du terrain",
    description: "Participe à 5 matchs",
    xp_reward:   150,
    icon_emoji:  "🔥",
    category:    "match"
  },
  {
    key:         "matches_10",
    name:        "Vétéran",
    description: "Participe à 10 matchs",
    xp_reward:   300,
    icon_emoji:  "🌟",
    category:    "match"
  },
  {
    key:         "first_match_created",
    name:        "Organisateur en herbe",
    description: "Crée ton premier match",
    xp_reward:   100,
    icon_emoji:  "🏟️",
    category:    "match"
  },
  {
    key:         "organized_3",
    name:        "Chef d'équipe",
    description: "Organise 3 matchs",
    xp_reward:   200,
    icon_emoji:  "🎯",
    category:    "match"
  },
  # ── Catégorie SOCIAL ─────────────────────────────────────────────────────────
  {
    key:         "first_message",
    name:        "Première prise de parole",
    description: "Envoie ton premier message dans un chat",
    xp_reward:   25,
    icon_emoji:  "💬",
    category:    "social"
  },
  {
    key:         "messages_10",
    name:        "Grande gueule",
    description: "Envoie 10 messages au total",
    xp_reward:   100,
    icon_emoji:  "🗣️",
    category:    "social"
  },
  # ── Catégorie PROFIL ─────────────────────────────────────────────────────────
  {
    key:         "profile_complete",
    name:        "Identité complète",
    description: "Complète ton profil (avatar, description et téléphone)",
    xp_reward:   75,
    icon_emoji:  "👤",
    category:    "profile"
  },
  # ── Nouveaux MATCH ─────────────────────────────────────────────────────────
  {
    key:         "matches_25",
    name:        "Légende du terrain",
    description: "Participe à 25 matchs",
    xp_reward:   500,
    icon_emoji:  "🏆",
    category:    "match"
  },
  {
    key:         "matches_50",
    name:        "Roi des terrains",
    description: "Participe à 50 matchs",
    xp_reward:   1000,
    icon_emoji:  "👑",
    category:    "match"
  },
  {
    key:         "organized_10",
    name:        "Général des terrains",
    description: "Organise 10 matchs",
    xp_reward:   400,
    icon_emoji:  "🎖️",
    category:    "match"
  },
  # ── Nouveaux SOCIAL ────────────────────────────────────────────────────────
  {
    key:         "messages_50",
    name:        "Voix du stade",
    description: "Envoie 50 messages au total",
    xp_reward:   250,
    icon_emoji:  "📢",
    category:    "social"
  },
  # ── Nouveaux PROFIL ────────────────────────────────────────────────────────
  {
    key:         "avatar_added",
    name:        "Visage révélé",
    description: "Ajoute une photo de profil",
    xp_reward:   50,
    icon_emoji:  "📸",
    category:    "profile"
  },
  {
    key:         "description_written",
    name:        "Ma story",
    description: "Rédige ta description de profil",
    xp_reward:   30,
    icon_emoji:  "✍️",
    category:    "profile"
  },

  # ── MATCH — Nouveaux ──────────────────────────────────────────────────────
  {
    key:         "matches_75",
    name:        "Indestructible",
    description: "Participe à 75 matchs",
    xp_reward:   750,
    icon_emoji:  "🛡️",
    category:    "match"
  },
  {
    key:         "matches_100",
    name:        "Centurion",
    description: "Participe à 100 matchs",
    xp_reward:   1500,
    icon_emoji:  "🥇",
    category:    "match"
  },
  {
    key:         "organized_25",
    name:        "Directeur sportif",
    description: "Organise 25 matchs",
    xp_reward:   700,
    icon_emoji:  "📋",
    category:    "match"
  },
  {
    key:         "hat_trick",
    name:        "Hat-trick",
    description: "Rejoins 3 matchs en 7 jours",
    xp_reward:   125,
    icon_emoji:  "⚡",
    category:    "match"
  },
  {
    key:         "night_owl",
    name:        "Joueur nocturne",
    description: "Participe à un match après 20h",
    xp_reward:   80,
    icon_emoji:  "🌙",
    category:    "match"
  },
  {
    key:         "sport_explorer",
    name:        "Touche-à-tout",
    description: "Pratique 3 sports différents",
    xp_reward:   200,
    icon_emoji:  "🎽",
    category:    "match"
  },
  {
    key:         "early_bird",
    name:        "Lève-tôt",
    description: "Participe à un match avant 9h",
    xp_reward:   80,
    icon_emoji:  "🌅",
    category:    "match"
  },

  # ── SOCIAL — Nouveaux ─────────────────────────────────────────────────────
  {
    key:         "messages_100",
    name:        "DJ du vestiaire",
    description: "Envoie 100 messages au total",
    xp_reward:   350,
    icon_emoji:  "🎙️",
    category:    "social"
  },
  {
    key:         "messages_250",
    name:        "Inarrêtable",
    description: "Envoie 250 messages au total",
    xp_reward:   600,
    icon_emoji:  "💥",
    category:    "social"
  },
  {
    key:         "first_review",
    name:        "Juge de touche",
    description: "Laisse ton premier avis sur un joueur",
    xp_reward:   40,
    icon_emoji:  "🌟",
    category:    "social"
  },
  {
    key:         "reviews_5",
    name:        "Arbitre confirmé",
    description: "Laisse 5 avis sur des joueurs",
    xp_reward:   120,
    icon_emoji:  "⚖️",
    category:    "social"
  },

  # ── PROFIL — Nouveaux ─────────────────────────────────────────────────────
  {
    key:         "phone_added",
    name:        "Joignable",
    description: "Ajoute ton numéro de téléphone",
    xp_reward:   25,
    icon_emoji:  "📱",
    category:    "profile"
  },
  {
    key:         "location_added",
    name:        "Localisé",
    description: "Renseigne ta ville",
    xp_reward:   25,
    icon_emoji:  "📍",
    category:    "profile"
  },
  {
    key:         "achievement_collector",
    name:        "Collectionneur",
    description: "Débloque 10 achievements",
    xp_reward:   400,
    icon_emoji:  "💎",
    category:    "profile"
  },
  {
    key:         "og_player",
    name:        "OG",
    description: "Membre depuis plus d'un an",
    xp_reward:   300,
    icon_emoji:  "🎂",
    category:    "profile"
  },
  {
    key:         "comeback",
    name:        "Revenant",
    description: "Reviens jouer après 30 jours d'absence",
    xp_reward:   100,
    icon_emoji:  "🔄",
    category:    "match"
  }
]

achievements_data.each do |data|
  # find_or_create_by! cherche d'abord par la clé unique, crée si introuvable
  achievement = Achievement.find_or_create_by!(key: data[:key]) do |a|
    a.name        = data[:name]
    a.description = data[:description]
    a.xp_reward   = data[:xp_reward]
    a.icon_emoji  = data[:icon_emoji]
    a.category    = data[:category]
  end
  puts "  ✓ #{achievement.icon_emoji} #{achievement.name} (#{achievement.xp_reward} XP)"
end

puts "#{Achievement.count} achievements en base."
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
    .last

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
        match:         completed_match,
        rating: 5,
        content: "Super joueur, ponctuel et fair-play. Je recommande !")

      # Avis de B vers A
      Avis.find_or_create_by!(
        reviewer:      user_b,
        reviewed_user: user_a,
        match:         completed_match,
        rating: 5,
        content: "Bonne technique, bon esprit d'équipe.")

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

# ── Amis fictifs ──────────────────────────────────────────────────────────────
# Crée 5 utilisateurs avec profil et les lie comme amis acceptés au 1er user
# Idempotent : find_or_create_by! sur l'email
require 'open-uri'
require 'cgi'
puts "Création des amis fictifs..."

# Helper : télécharge un avatar depuis DiceBear et l'attache au profil
# Skippé si l'avatar est déjà présent (idempotent)
# CGI.escape gère les caractères spéciaux dans le seed (accents, etc.)
def attach_seed_avatar(profil, style, seed, filename)
  return if profil.avatar.attached?
  url = "https://api.dicebear.com/7.x/#{style}/png?seed=#{CGI.escape(seed)}&size=200"
  profil.avatar.attach(
    io:           URI.open(url),
    filename:     filename,
    content_type: "image/png"
  )
rescue => e
  puts "  ⚠️  Avatar non chargé (#{filename}) : #{e.message}"
end

# On prend le premier utilisateur en base comme "utilisateur principal"
main_user = User.first

if main_user.nil?
  puts "⚠️  Aucun utilisateur trouvé, les amis fictifs ne seront pas créés."
else
  # avatar_style : "big-ears" pour les hommes, "lorelei" pour les femmes (DiceBear v7)
  fake_friends_data = [
    { first_name: "Lucas",   last_name: "Martin",   email: "lucas.martin@seed.com",   level: "Intermédiaire", localisation: "Paris",     description: "Passionné de foot et de padel, toujours partant pour un match !", avatar_style: "big-ears"  },
    { first_name: "Emma",    last_name: "Dupont",   email: "emma.dupont@seed.com",     level: "Débutant",      localisation: "Lyon",      description: "Nouvelle dans le sport collectif, j'adore le volleyball.",        avatar_style: "lorelei"   },
    { first_name: "Théo",    last_name: "Bernard",  email: "theo.bernard@seed.com",    level: "Expert",        localisation: "Bordeaux",  description: "10 ans de basket, capitaine de mon équipe en amateur.",           avatar_style: "big-ears"  },
    { first_name: "Camille", last_name: "Leroy",    email: "camille.leroy@seed.com",   level: "Intermédiaire", localisation: "Nantes",    description: "Tennis et badminton le week-end, bonne humeur garantie.",         avatar_style: "lorelei"   },
    { first_name: "Noah",    last_name: "Moreau",   email: "noah.moreau@seed.com",     level: "Débutant",      localisation: "Marseille", description: "Je découvre le football à 5, prêt à apprendre !",                 avatar_style: "big-ears"  }
  ]

  fake_friends_data.each do |data|
    # Crée l'utilisateur s'il n'existe pas déjà
    # first_name et last_name sont des attr_accessor requis à la création (pour Devise)
    friend_user = User.find_by(email: data[:email])
    unless friend_user
      friend_user = User.create!(
        email:      data[:email],
        password:   "Password1!",
        first_name: data[:first_name],
        last_name:  data[:last_name]
      )
    end

    # Crée ou met à jour le profil
    profil = friend_user.profil || friend_user.build_profil
    profil.first_name   = data[:first_name]
    profil.last_name    = data[:last_name]
    profil.level        = data[:level]
    profil.localisation = data[:localisation]
    profil.description  = data[:description]
    profil.save!

    # Attache l'avatar DiceBear (skippé si déjà présent)
    attach_seed_avatar(profil, data[:avatar_style], data[:first_name], "#{data[:first_name].downcase}_avatar.png")

    # Crée l'amitié acceptée si elle n'existe pas encore
    already_friends = Friendship.exists?(user: main_user, friend: friend_user) ||
                      Friendship.exists?(user: friend_user, friend: main_user)

    unless already_friends
      Friendship.create!(
        user:   main_user,
        friend: friend_user,
        status: "accepted"
      )
      puts "  ✓ Ami créé : #{data[:first_name]} #{data[:last_name]}"
    else
      puts "  → Déjà ami : #{data[:first_name]} #{data[:last_name]}"
    end
  end

  puts "✅ #{main_user.all_friends.count} amis au total pour #{main_user.email}."
end

# ── Joueurs invitables (sans amitié, juste des comptes existants) ──────────────
# Ces joueurs peuvent être invités via la recherche par email ou prénom
puts "Création des joueurs invitables..."

invitable_data = [
  { first_name: "Jules",  last_name: "Petit",    email: "jules.petit@seed.com",    level: "Intermédiaire", localisation: "Toulouse",    description: "Footeux du dimanche, mais sérieux quand il le faut.",         avatar_style: "big-ears" },
  { first_name: "Inès",   last_name: "Rousseau", email: "ines.rousseau@seed.com",  level: "Expert",        localisation: "Strasbourg",  description: "Capitaine de mon équipe de handball en D3 régionale.",        avatar_style: "lorelei"  }
]

invitable_data.each do |data|
  # Crée le compte s'il n'existe pas encore
  user = User.find_by(email: data[:email])
  unless user
    user = User.create!(
      email:      data[:email],
      password:   "Password1!",
      first_name: data[:first_name],
      last_name:  data[:last_name]
    )
  end

  # Crée ou met à jour le profil
  profil = user.profil || user.build_profil
  profil.first_name   = data[:first_name]
  profil.last_name    = data[:last_name]
  profil.level        = data[:level]
  profil.localisation = data[:localisation]
  profil.description  = data[:description]
  profil.save!

  # Attache l'avatar DiceBear (skippé si déjà présent)
  # Correction : attach_seed_avatar attend 4 args (profil, style, seed, filename)
  attach_seed_avatar(profil, data[:avatar_style], data[:first_name], "#{data[:first_name].downcase}_avatar.png")

  # Lie comme ami accepté avec le main_user (pour apparaître dans "Proposer un joueur")
  if main_user
    already_friends = Friendship.exists?(user: main_user, friend: user) ||
                      Friendship.exists?(user: user, friend: main_user)
    unless already_friends
      Friendship.create!(user: main_user, friend: user, status: "accepted")
    end
  end

  puts "  ✓ Joueur invitable : #{data[:first_name]} #{data[:last_name]} (#{data[:email]})"
end

puts "✅ Joueurs invitables créés."

# ── Matchs de test avec acceptation automatique ──────────────────────────────
# Ces matchs sont créés en mode "automatic" : tout joueur qui rejoint est
# immédiatement accepté (status "approved") sans intervention de l'organisateur.
# Utile pour tester le flux d'inscription, le chat, les votes, etc.
puts "Création des matchs de test (acceptation automatique)..."

# On récupère le premier utilisateur disponible comme organisateur
organizer = User.joins(:profil).first

if organizer.nil?
  puts "⚠️  Aucun utilisateur avec profil trouvé. Les matchs de test ne seront pas créés."
else
  # On récupère les sports Football et Basketball qui ont des niveaux simples
  football   = Sport.find_by(slug: "football")
  basketball = Sport.find_by(slug: "basketball")
  padel      = Sport.find_by(slug: "padel")

  # Liste des matchs à créer
  # Les dates sont dans le futur (≥ 30 min à l'avance, validation du modèle Match)
  test_matches_data = [
    {
      title:           "Match football test — 5v5",
      description:     "Match de test pour la démo. Ambiance détendue, venez nombreux !",
      place:           "Stade Jean-Bouin, Paris",
      date:            Date.today + 3.days,   # Dans 3 jours → passe la validation 30min
      time:            Time.zone.parse("10:00"), # 10h du matin
      format:          "5v5",
      level:           "Amateur",
      player_left:     8,                     # 8 places restantes (sur 9 total, organisateur compris)
      players_present: nil,                   # Pas utilisé pour le format 5v5
      price_per_player: 5,
      validation_mode: "automatic",           # Acceptation automatique → pas besoin d'approuver manuellement
      visibility:      "public",
      genre_restriction: "tous",
      sport:           football
    },
    {
      title:           "Basket 3v3 test — niveau intermédiaire",
      description:     "Partie de basket détendue pour tester le système de matchs.",
      place:           "Gymnase Charléty, Paris 13",
      date:            Date.today + 5.days,
      time:            Time.zone.parse("18:30"),
      format:          "3v3",
      level:           "Intermédiaire",
      player_left:     5,
      players_present: nil,
      price_per_player: 0,
      validation_mode: "automatic",
      visibility:      "public",
      genre_restriction: "tous",
      sport:           basketball
    },
    {
      title:           "Padel confirmé — match test",
      description:     "Match de padel en mode test. Niveau confirmé requis.",
      place:           "Court Padel Nation, Paris 12",
      date:            Date.today + 7.days,
      time:            Time.zone.parse("14:00"),
      format:          "2v2",
      level:           "Confirmé",
      player_left:     3,
      players_present: nil,
      price_per_player: 10,
      validation_mode: "automatic",
      visibility:      "public",
      genre_restriction: "tous",
      sport:           padel
    }
  ]

  test_matches_data.each do |data|
    # On saute si le sport n'existe pas en base (protection contre des seeds incomplets)
    unless data[:sport]
      puts "  ⚠️  Sport introuvable pour « #{data[:title]} », skippé."
      next
    end

    # Vérifie si un match du même titre existe déjà (idempotent)
    if Match.exists?(title: data[:title])
      puts "  → Déjà existant : #{data[:title]}"
      next
    end

    # Crée le match — validation_mode "automatic" = le créateur n'a pas à approuver les joueurs
    match = Match.new(
      title:             data[:title],
      description:       data[:description],
      place:             data[:place],
      date:              data[:date],
      time:              data[:time],
      format:            data[:format],
      level:             data[:level],
      player_left:       data[:player_left],
      price_per_player:  data[:price_per_player],
      validation_mode:   data[:validation_mode],   # "automatic" → inscription directe
      visibility:        data[:visibility],
      genre_restriction: data[:genre_restriction],
      sport:             data[:sport],
      user:              organizer                 # L'organisateur est le premier user en base
    )

    # players_present n'est obligatoire que pour le format "Libre"
    match.players_present = data[:players_present] if data[:players_present]

    match.save!

    # Crée l'inscription de l'organisateur avec le rôle "organisateur" et statut "approved"
    # En production, c'est le MatchesController#create qui le fait automatiquement.
    # Ici on le recrée manuellement pour que le match soit complet dès le seed.
    MatchUser.find_or_create_by!(match: match, user: organizer) do |mu|
      mu.role   = "organisateur"
      mu.status = "approved"  # L'organisateur est toujours approuvé d'emblée
    end

    # Ajoute 2 participants supplémentaires avec statut "approved" (acceptation automatique simulée)
    # On prend les amis du main_user s'ils existent
    participants = User.joins(:profil)
                       .where.not(id: organizer.id)
                       .limit(2)

    participants.each do |participant|
      # Vérifie qu'il n'est pas déjà inscrit à ce match
      next if MatchUser.exists?(match: match, user: participant)

      MatchUser.create!(
        match:  match,
        user:   participant,
        role:   "joueur",
        status: "approved"  # Simulé comme si le mode "automatic" avait déjà approuvé
      )
      puts "    + Participant ajouté : #{participant.profil.first_name} #{participant.profil.last_name}"
    end

    puts "  ✓ Match créé : « #{match.title} » (#{match.sport.name}, #{match.date}, #{match.level})"
  end

  puts "✅ #{Match.where(validation_mode: 'automatic').count} matchs en mode automatique en base."
end

# ── Matchs badminton — un par statut d'inscription ───────────────────────────
# Crée 4 matchs de badminton où le 2ème user (main_user ou premier non-organisateur)
# est inscrit avec chacun des 4 statuts possibles : approved, pending, waiting, rejected.
# Utile pour tester visuellement les badges sur les cards.
puts "Création des matchs badminton (un par statut)..."

badminton = Sport.find_by(slug: "badminton")

# L'organisateur de ces matchs = 2ème user en base (différent du "main_user" pour que
# le 1er user (main_user) puisse être inscrit comme joueur avec chaque statut)
organizer_for_badminton = User.joins(:profil).offset(1).first
# Le joueur à inscrire = le 1er user (celui qui se connecte pour voir les badges)
test_player = User.joins(:profil).first

if badminton.nil?
  puts "⚠️  Sport badminton introuvable — vérifie que les sports ont été créés."
elsif organizer_for_badminton.nil? || test_player.nil?
  puts "⚠️  Pas assez d'utilisateurs avec profil pour les matchs badminton."
elsif organizer_for_badminton == test_player
  puts "⚠️  Il faut au moins 2 utilisateurs distincts pour ces matchs de test."
else
  # Chaque entrée = { statut d'inscription du test_player, données du match }
  badminton_status_matches = [
    {
      player_status: "approved",             # test_player inscrit et accepté
      title:         "[TEST] Badminton — Inscrit (approved)",
      description:   "Match de test : le joueur est inscrit et accepté.",
      level:         "Intermédiaire",
      format:        "2v2",
      player_left:   2,                      # encore de la place
      date:          Date.today + 4.days,
      time:          Time.zone.parse("09:00"),
      validation_mode: "manual"              # mode manuel pour que les autres statuts aient du sens
    },
    {
      player_status: "pending",              # test_player en attente de validation
      title:         "[TEST] Badminton — En attente (pending)",
      description:   "Match de test : le joueur attend la validation du capitaine.",
      level:         "Confirmé",
      format:        "1v1",
      player_left:   1,
      date:          Date.today + 6.days,
      time:          Time.zone.parse("11:00"),
      validation_mode: "manual"
    },
    {
      player_status: "waiting",              # test_player en file d'attente (match complet)
      title:         "[TEST] Badminton — File d'attente (waiting)",
      description:   "Match de test : le match est complet, le joueur est en file d'attente.",
      level:         "Débutant",
      format:        "2v2",
      # player_left: 1 à la création (la validation interdit 0).
      # On forcera à 0 avec update_column après le save! pour simuler un match complet.
      player_left:   1,
      date:          Date.today + 8.days,
      time:          Time.zone.parse("14:00"),
      validation_mode: "manual",
      force_full: true                       # flag interne pour déclencher le update_column
    },
    {
      player_status: "rejected",             # test_player refusé par le capitaine
      title:         "[TEST] Badminton — Refusé (rejected)",
      description:   "Match de test : la candidature du joueur a été refusée.",
      level:         "Expert",
      format:        "1v1",
      player_left:   1,
      date:          Date.today + 10.days,
      time:          Time.zone.parse("16:00"),
      validation_mode: "manual"
    }
  ]

  badminton_status_matches.each do |data|
    # Idempotent : on ne recrée pas si le titre existe déjà
    if Match.exists?(title: data[:title])
      puts "  → Déjà existant : #{data[:title]}"
      next
    end

    # Crée le match — l'organisateur est un user différent de test_player
    match = Match.new(
      title:             data[:title],
      description:       data[:description],
      place:             "Gymnase du Palais des Sports, Paris",
      date:              data[:date],
      time:              data[:time],
      format:            data[:format],
      level:             data[:level],
      player_left:       data[:player_left],
      price_per_player:  0,
      validation_mode:   data[:validation_mode],
      visibility:        "public",
      genre_restriction: "tous",
      sport:             badminton,
      user:              organizer_for_badminton  # pas le test_player → les badges s'affichent
    )
    match.save!

    # Cas particulier "waiting" : player_left = 0 est refusé par la validation du modèle.
    # On contourne avec update_column (bypass validations) uniquement pour ce match de test.
    match.update_column(:player_left, 0) if data[:force_full]

    # Inscrit l'organisateur (rôle "organisateur", toujours approuvé)
    MatchUser.find_or_create_by!(match: match, user: organizer_for_badminton) do |mu|
      mu.role   = "organisateur"
      mu.status = "approved"
    end

    # Inscrit test_player avec le statut voulu — c'est ce statut qui déclenchera le badge
    MatchUser.create!(
      match:  match,
      user:   test_player,
      role:   "joueur",
      status: data[:player_status]   # "approved" | "pending" | "waiting" | "rejected"
    )

    puts "  ✓ #{data[:title]} → #{test_player.profil.first_name} = #{data[:player_status]}"
  end

  puts "✅ Matchs badminton de test créés."
end

# ── Matchs tennis — tous les statuts pour Marvin COHEN ───────────────────────
# Crée 5 matchs de tennis couvrant chaque situation possible sur une card :
#   approved, pending, waiting, rejected + organisateur (brassard C)
# Marvin COHEN (id 10) est le joueur cible pour les 4 premiers, et l'organisateur du 5ème.
puts "Création des matchs tennis (tous statuts) pour Marvin COHEN..."

tennis  = Sport.find_by(slug: "tennis")
marvin  = User.find_by(email: "marvincohen95@gmail.com")

# L'organisateur des matchs où Marvin est joueur = un autre user existant
other_organizer = User.joins(:profil).where.not(id: marvin&.id).first

if tennis.nil?
  puts "⚠️  Sport tennis introuvable."
elsif marvin.nil?
  puts "⚠️  Utilisateur marvincohen95@gmail.com introuvable."
elsif other_organizer.nil?
  puts "⚠️  Pas d'autre utilisateur disponible comme organisateur."
else

  tennis_matches = [
    # ── 1. Marvin inscrit et ACCEPTÉ ──────────────────────────────────────────
    {
      player_status:   "approved",
      title:           "[TEST] Tennis — Inscrit (approved)",
      description:     "Marvin est inscrit et accepté. Overlay vert INSCRIT.",
      level:           "Intermédiaire",
      format:          "1v1",
      player_left:     1,
      date:            Date.today + 3.days,
      time:            Time.zone.parse("09:00"),
      validation_mode: "manual",
      organizer:       other_organizer,
      player:          marvin
    },
    # ── 2. Marvin EN ATTENTE de validation ────────────────────────────────────
    {
      player_status:   "pending",
      title:           "[TEST] Tennis — En attente (pending)",
      description:     "Marvin attend la validation du capitaine. Overlay orange EN ATTENTE.",
      level:           "Confirmé",
      format:          "2v2",
      player_left:     3,
      date:            Date.today + 5.days,
      time:            Time.zone.parse("11:00"),
      validation_mode: "manual",
      organizer:       other_organizer,
      player:          marvin
    },
    # ── 3. Marvin en FILE D'ATTENTE (match complet) ───────────────────────────
    {
      player_status:   "waiting",
      title:           "[TEST] Tennis — File d'attente (waiting)",
      description:     "Match complet, Marvin est en file d'attente. Overlay gris FILE D'ATTENTE.",
      level:           "Débutant",
      format:          "1v1",
      player_left:     1,     # Sera forcé à 0 via update_column après save
      date:            Date.today + 7.days,
      time:            Time.zone.parse("14:00"),
      validation_mode: "manual",
      organizer:       other_organizer,
      player:          marvin,
      force_full:      true   # player_left → 0 après save (bypass validation)
    },
    # ── 4. Marvin REFUSÉ par le capitaine ─────────────────────────────────────
    {
      player_status:   "rejected",
      title:           "[TEST] Tennis — Refusé (rejected)",
      description:     "Candidature refusée. Overlay rouge NON RETENU.",
      level:           "Expert",
      format:          "2v2",
      player_left:     3,
      date:            Date.today + 9.days,
      time:            Time.zone.parse("16:00"),
      validation_mode: "manual",
      organizer:       other_organizer,
      player:          marvin
    },
    # ── 5. Marvin est l'ORGANISATEUR ──────────────────────────────────────────
    {
      player_status:   nil,    # Pas de joueur à inscrire — Marvin est le créateur
      title:           "[TEST] Tennis — Organisateur (ton match)",
      description:     "Marvin a créé ce match. Brassard C + label 'Ton match'.",
      level:           "Avancé",
      format:          "1v1",
      player_left:     1,
      date:            Date.today + 11.days,
      time:            Time.zone.parse("10:00"),
      validation_mode: "automatic",
      organizer:       marvin,  # Marvin est l'organisateur ici
      player:          nil
    }
  ]

  tennis_matches.each do |data|
    # Idempotent
    if Match.exists?(title: data[:title])
      puts "  → Déjà existant : #{data[:title]}"
      next
    end

    # Crée le match avec l'organisateur désigné
    match = Match.new(
      title:             data[:title],
      description:       data[:description],
      place:             "Tennis Club de Paris, Paris 16",
      date:              data[:date],
      time:              data[:time],
      format:            data[:format],
      level:             data[:level],
      player_left:       data[:player_left],
      price_per_player:  0,
      validation_mode:   data[:validation_mode],
      visibility:        "public",
      genre_restriction: "tous",
      sport:             tennis,
      user:              data[:organizer]
    )
    match.save!

    # Cas "waiting" : force player_left à 0 pour simuler un match complet
    match.update_column(:player_left, 0) if data[:force_full]

    # Inscrit l'organisateur
    MatchUser.find_or_create_by!(match: match, user: data[:organizer]) do |mu|
      mu.role   = "organisateur"
      mu.status = "approved"
    end

    # Inscrit Marvin avec le statut voulu (sauf s'il est l'organisateur)
    if data[:player].present?
      MatchUser.create!(
        match:  match,
        user:   data[:player],
        role:   "joueur",
        status: data[:player_status]
      )
      puts "  ✓ #{data[:title]}"
      puts "       └─ Marvin = #{data[:player_status]}"
    else
      puts "  ✓ #{data[:title]}"
      puts "       └─ Marvin = organisateur"
    end
  end

  puts "✅ Matchs tennis créés pour Marvin COHEN."
end
