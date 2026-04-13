---
name: Modération d'images par IA
status: draft
created: 2026-04-10
---

# Modération automatique des images utilisateur

## Contexte

Les utilisateurs peuvent uploader trois types d'images :
- [app/models/profil.rb:10](app/models/profil.rb#L10) — `Profil#avatar`
- [app/models/team.rb:16](app/models/team.rb#L16) — `Team#badge_image`
- [app/models/team.rb:19](app/models/team.rb#L19) — `Team#cover_image`

On veut détecter automatiquement les images NSFW et, en cas de rejet, purger l'image, notifier l'utilisateur et laisser le fallback "initiales" existant ([app/helpers/application_helper.rb:88](app/helpers/application_helper.rb#L88)) prendre le relais sur les avatars.

## Décisions actées

| Décision | Choix |
|---|---|
| Moteur IA | **Sightengine** (`nudity-2.1`) via API REST |
| Raison | Free tier 2000 ops/mois illimité dans le temps, couvre notre cible 2000 users × 1 image/mois pile poil. Sur-ensemble fonctionnel de Falconsai (couvre aussi violence/armes/drogues si on en a besoin plus tard). Infra commerciale stable. |
| Alternatives écartées | HF Falconsai (quota ~$0.10/mois = 500-1500 appels, trop serré), ONNX-in-Ruby (slug/RAM Heroku), sidecar VPS (coûte 4€/mois), Cloudinary add-on (payant) |
| Architecture | Pattern **adapter** pour pouvoir switcher de provider sans réécrire le reste |
| HTTP client | `net/http` natif (pas de dépendance ajoutée, POST multipart suffit) |
| Exécution | **Asynchrone** via ActiveJob + Solid Queue (déjà en place en prod) |
| Stratégie de rejet | Purge de l'attachement + `Notification` in-app + fallback initiales (automatique) |
| Règle de score | `max(sexual_activity, sexual_display, erotica, very_suggestive) >= 0.8` → rejet |
| Catégories ignorées | Tout `suggestive_classes` (bikini, cleavage, male_chest, swimwear…) — contexte sportif légitime |
| Périmètre | Nouveaux uploads **et** existant (rake task) |
| Notification | In-app uniquement (pas d'email) |
| Notification sur purge rétroactive | Oui, l'utilisateur est prévenu |
| Ton du message | Pédagogique — mentionner la possibilité de contacter le support en cas de faux positif |
| Volume actuel / cible | Centaines au lancement, cible 2000+ users rapidement |
| Plafond Sightengine free | 2000 ops/mois, **max 500/jour** — contrainte pour la rake task de backfill |
| Stratégie en cas de dépassement quota | **Fail-open** : statut `errored`, image reste visible, admin alerté. On préfère un faux négatif temporaire à un blocage massif. |
| Alerte quota | Notification admin dès qu'on atteint 80% du quota mensuel |

## Architecture

### Modèle de données

Une seule table polymorphique pour centraliser la modération :

```
image_moderations
├── id
├── moderatable_type      # "Profil" | "Team"
├── moderatable_id
├── attachment_name       # "avatar" | "badge_image" | "cover_image"
├── status                # enum: pending | approved | rejected | errored
├── score                 # decimal(5,4)  — proba NSFW retournée par le modèle
├── reason                # string — "nsfw_detected" | "api_error" | …
├── checked_at            # datetime
├── created_at / updated_at
└── index unique [moderatable_type, moderatable_id, attachment_name]
```

Avantages :
- Une seule table à administrer
- Historique conservé même après purge
- Admin interface uniforme (pas besoin de jongler entre Profil/Team)

### Services

```
app/services/image_moderation/
├── checker.rb              # API publique : Checker.call(record, :attachment_name)
├── adapters/
│   ├── base.rb             # Interface commune : #analyze(io, filename:) → Result
│   └── sightengine.rb      # Impl. Sightengine check.json (multipart POST)
├── result.rb               # Value object : score, label, raw_response
└── errors.rb               # RateLimitError, QuotaExceededError, ApiError
```

`Checker.call(record, attachment_name)` :
1. Récupère le blob de l'attachement (via `blob.id` pour éviter les race conditions sur changement d'avatar)
2. Télécharge l'io en mémoire depuis Cloudinary (`blob.open`)
3. Appelle l'adapter configuré (`Sightengine` par défaut) avec l'io + filename
4. Crée ou met à jour `ImageModeration` avec le verdict (`score`, `reason`, `checked_at`)
5. Si `score >= 0.8` → purge l'attachement **avec flag skip_moderation** (éviter boucle) + crée `Notification`
6. Si erreur API → statut `errored`, image reste visible (fail-open)

### Job

`app/jobs/moderate_image_job.rb` :
- Reçoit `(record_gid, attachment_name)`
- Appelle `ImageModeration::Checker.call`
- `retry_on RateLimitError, wait: :polynomially_longer, attempts: 5`
- `discard_on RecordNotFound` (si l'image a été supprimée entre-temps)

### Hooks modèles

Dans `Profil` et `Team`, callback `after_commit` sur changement d'attachement :
```ruby
after_commit :enqueue_moderation, on: [:create, :update]

private

def enqueue_moderation
  ModerateImageJob.perform_later(to_gid_param, "avatar") if avatar.attached? && saved_change_to_attribute?("...")
end
```
À affiner : Active Storage ne passe pas par `saved_change_to_*`, il faut écouter le blob via `after_commit` sur `ActiveStorage::Attachment` ou utiliser un concern dédié. **Cf. étape 4 pour la recherche exacte.**

### Gestion des erreurs API

- Rate limit Sightengine (429) → `retry_on RateLimitError` avec backoff exponentiel, max 5 tentatives
- Quota mensuel dépassé (erreur Sightengine `usage_limit`) → **QuotaExceededError**, PAS de retry, statut `errored` direct + alerte admin
- Timeout / 5xx → `retry_on ApiError`, max 5 tentatives
- Après N échecs → status `errored`, visible dans l'admin pour retry manuel
- **Fail-open** : jamais de blocage du user. Si l'API est down OU quota dépassé, l'image reste visible en `errored`. On préfère un faux négatif temporaire à un blocage massif.
- **Alerte quota 80%** : un compteur `ImageModeration.where(checked_at: Time.current.beginning_of_month..).count` monitoré dans le dashboard admin, notification admin déclenchée quand on atteint 1600 ops (80% de 2000)

### Admin

Nouvelle section dans l'espace admin existant :
- `admin/image_moderations#index` — filtres par statut (pending/approved/rejected/errored), date, type
- `admin/image_moderations#show` — détail d'une modération (image, score, reason, possibilité de revalider ou reforcer le rejet)
- Actions : `approve!`, `reject!`, `re_moderate!`
- Stats en haut du dashboard admin : nb rejetés aujourd'hui / cette semaine

### Notification

Nouveau type dans `Notification` :
- `notification_type: "image_rejected"`
- Ton **pédagogique** avec porte de sortie vers le support en cas de faux positif
- Exemple (avatar) : "Votre photo de profil a été automatiquement retirée car notre système de modération a détecté un contenu potentiellement inapproprié. Vous pouvez en uploader une nouvelle à tout moment. Si vous pensez qu'il s'agit d'une erreur, contactez-nous via le formulaire de contact."
- Variantes selon attachment_name (avatar / blason d'équipe / bannière d'équipe)
- Lien direct vers la page concernée (édition profil ou édition équipe)

## Étapes d'implémentation

### Phase 1 — Fondations (backend)
- [x] 1.1 — ~~Ajouter gem HTTP client~~ → décision : `net/http` natif (aucune dépendance ajoutée)
- [ ] 1.2 — Ajouter `SIGHTENGINE_API_USER` et `SIGHTENGINE_API_SECRET` à `.env.example` (Heroku plus tard, quand le local est validé)
- [ ] 1.3 — Créer migration `create_image_moderations` avec index unique `[moderatable_type, moderatable_id, attachment_name]`
- [ ] 1.4 — Créer modèle `ImageModeration` avec enum status (pending/approved/rejected/errored) + associations polymorphiques + scope `this_month`
- [ ] 1.5 — Créer `ImageModeration::Adapters::Base` (interface abstraite avec `#analyze(io, filename:)`)
- [ ] 1.6 — Créer `ImageModeration::Result` (value object : score, label, reason, raw)
- [ ] 1.7 — Créer `ImageModeration::Errors` (RateLimitError, QuotaExceededError, ApiError)
- [ ] 1.8 — Créer `ImageModeration::Adapters::Sightengine` (POST multipart via net/http, parsing `nudity.*`, gestion erreurs)
- [ ] 1.9 — Créer `ImageModeration::Checker` (orchestration : blob → download → analyze → save → act)
- [ ] 1.10 — Créer `ModerateImageJob` avec `retry_on RateLimitError, ApiError` + `discard_on ActiveRecord::RecordNotFound`
- [ ] 1.11 — Tests unitaires : adapter (avec stub net/http), checker (avec fake adapter), job

### Phase 2 — Intégration modèles
- [ ] 2.1 — Recherche : meilleure pratique Rails 8 pour déclencher un job sur changement d'`has_one_attached`
- [ ] 2.2 — Créer concern `Moderatable` avec méthode `moderate_attachment(:name)`
- [ ] 2.3 — Inclure `Moderatable` dans `Profil` (avatar) et `Team` (badge_image, cover_image)
- [ ] 2.4 — Vérifier que la purge ne déclenche pas de boucle infinie de modération
- [ ] 2.5 — Tests d'intégration : upload → job enqueue → modération → purge si rejeté

### Phase 3 — Notifications
- [ ] 3.1 — Ajouter `notification_type: "image_rejected"` + locales FR
- [ ] 3.2 — Créer partial pour affichage dans la cloche existante
- [ ] 3.3 — Méthode `Notification.image_rejected!(user, attachment_name)` dans le modèle
- [ ] 3.4 — Vérifier que le broadcast ActionCable fonctionne (la cloche se met à jour en live)

### Phase 4 — Fallback visuel pour équipes
- [ ] 4.1 — Vérifier comment les vues affichent `badge_image` et `cover_image` aujourd'hui (partials concernés déjà identifiés : `teams/show`, `teams/_form`, `teams/_team_card`)
- [ ] 4.2 — Pour le blason : utiliser la méthode `Team#badge_display` existante ([team.rb:78](app/models/team.rb#L78)) qui gère déjà la priorité `badge_image > badge_svg`. Si `badge_image` est purgé, le `badge_svg` (sanitized) prend naturellement le relais.
- [ ] 4.3 — Pour la bannière : créer helper `team_cover_tag(team)` avec fallback gradient/couleur unie si `cover_image` absent
- [ ] 4.4 — S'assurer que toutes les vues utilisent `badge_display` (ou un helper équivalent) plutôt que `team.badge_image.attached?` en direct, pour que le fallback soit uniforme

### Phase 5 — Admin
- [ ] 5.1 — Créer `Admin::ImageModerationsController` héritant de `Admin::BaseController`
- [ ] 5.2 — Routes + Pundit policy `ImageModerationPolicy` (admin seulement)
- [ ] 5.3 — Vue index avec filtres + pagination (Pagy)
- [ ] 5.4 — Vue show avec actions approve/reject/re_moderate
- [ ] 5.5 — Widget stats sur `admin/dashboard#index` (nb rejets 24h/7j)
- [ ] 5.6 — Styles SCSS dans `pages/admin_image_moderations.scss`

### Phase 6 — Existant (rake task)
- [ ] 6.1 — Créer `lib/tasks/moderation.rake` avec `moderation:check_existing`
- [ ] 6.2 — Itérer sur les `Profil` avec avatar + `Team` avec badge/cover
- [ ] 6.3 — Enqueue `ModerateImageJob` avec `set(wait_until:)` croissant pour respecter le **plafond Sightengine 500 ops/jour**. Ex : 50 jobs/batch, 1 batch toutes les 2h pendant 10h → 250/jour, marge de sécurité.
- [ ] 6.4 — Compteur et logs pour suivre la progression (nb enqueue, nb restants)
- [ ] 6.5 — Documenter la commande dans le README (usage, durée estimée selon volume, précautions quota)

### Phase 7 — Validation
- [ ] 7.1 — Test manuel en dev : upload d'une image safe → approved
- [ ] 7.2 — Test manuel en dev : upload d'une image NSFW (image de test neutre avec score simulé) → rejected → notification reçue → fallback initiales affiché
- [ ] 7.3 — Test manuel admin : forcer re_moderate, approve manuel, reject manuel
- [ ] 7.4 — Test du rake task sur un subset en dev
- [ ] 7.5 — Vérifier logs Heroku après déploiement (pas d'erreurs API)

## Points de vigilance

- **Plafond Sightengine 500 ops/jour** : contrainte forte pour la rake task de backfill. Étaler impérativement. Au quotidien (nouveaux uploads) c'est transparent : on reçoit bien moins de 500 uploads/jour à 2000 users actifs.
- **Quota mensuel 2000 ops** : surveiller via dashboard admin. Au-delà → statut `errored` et fail-open.
- **Purge en cascade** : s'assurer que purger l'attachement ne supprime pas aussi l'`ImageModeration` (on veut garder l'historique). La relation est polymorphique sur le record (Profil/Team), pas sur le blob.
- **Race condition sur changement d'avatar** : si l'user change son avatar pendant qu'un job tourne sur l'ancien, le job ne doit pas purger le nouveau. Le job reçoit et manipule le `blob.id` de l'attachement original, pas la relation `record.avatar` qui peut avoir changé entre-temps.
- **Contexte sportif** : NE PAS rejeter sur `suggestive_classes.*` (bikini, male_chest, swimwear…) car une photo de beach volley ou natation doit passer. Seules les 4 catégories `sexual_activity`, `sexual_display`, `erotica`, `very_suggestive` sont évaluées.
- **Coût d'un faux positif** : un avatar légitime rejeté = user frustré. Avec seuil 0.8 et catégories restreintes, le risque est contenu, mais l'admin doit pouvoir rapidement approuver manuellement via `re_moderate!` ou `approve!`.
- **GDPR** : l'image rejetée est purgée immédiatement. Seul l'`ImageModeration` reste en base avec le score, sans l'image → conforme.
- **Boucle infinie purge→modération** : la purge déclenchée par la modération ne doit pas re-déclencher une modération. Utiliser `Thread.current[:skip_image_moderation] = true` autour du `purge` dans le Checker, ou filtrer dans le callback `Moderatable`.

## Ce qu'on ne fait PAS dans ce plan

- Détection de violence / armes / haine (hors scope du modèle Falconsai — à envisager plus tard avec un second adapter)
- Modération des images de match (photos uploadées par les joueurs sur un match — à traiter séparément si besoin)
- Modération humaine pré-publication (toutes les images sont publiées immédiatement, la modération IA tourne en arrière-plan)
- Détection de données personnelles dans les images (plaques, visages de tiers) — problème RGPD non résolvable automatiquement
