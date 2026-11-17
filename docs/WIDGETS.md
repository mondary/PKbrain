# Widgets PKbrain — état et intégration

## État de cette version

- Le drawer configurable fonctionne dans le build SwiftPM habituel.
- L'extension WidgetKit est implémentée (App Intents, choix d'une note,
  formats petit/moyen/grand, lien vers la note).
- Les sources de l'extension sont vérifiées par le compilateur, les exports
  par des tests sur données fictives.
- Le build complet de l'extension avec métadonnées App Intents a réussi
  dans la [CI du commit af45c7ad](https://github.com/mondary/PKbrain/actions/runs/43839333888).
- Vérifications locales du 16 novembre 2026 : bundle `2026.11.7-dev` installé
  dans `/Applications/PKbrain.app`, signature vérifiée, diagnostic
  `widgetExtensionEmbedded=true appGroupAvailable=true`, extension reconnue
  par `pluginkit` comme `com.apple.widgetkit-extension` avec le bon parent.
  Cela ne remplace pas un ajout manuel depuis la galerie.
- **L'apparition dans la galerie reste à tester sur ce Mac.** Xcode complet
  n'y est pas installé ; une extension construite en CI peut être signée
  localement avec un App Group macOS préfixé par le Team ID. Une compilation
  des sources n'est pas une validation du widget système.
- Le build ad-hoc ne prétend pas proposer des widgets : le partage est désactivé
  et les réglages Stickies indiquent ce prérequis.

## Fonctionnement prévu une fois la build widget installée

1. Dans une note, ouvrir **Aa**, puis **Autoriser cette note dans les widgets**.
2. Bureau macOS → **Modifier les widgets** → **PKbrain Note**.
3. Ajouter un widget, puis choisir une note dans **Modifier le widget**.
4. Un clic ouvre la note correspondante dans PKbrain.

Le widget reste sur le bureau lorsque l'app est fermée, pas au-dessus des
autres apps. macOS 14+ est requis pour ce parcours. Le système contrôle les
rafraîchissements : PKbrain demande une mise à jour après sauvegarde ou
changement d'autorisation, sans garantie de délai. Une note archivée,
supprimée ou dont l'autorisation est retirée disparaît de l'export au prochain
rafraîchissement ; l'ancien rendu peut subsister jusqu'au rafraîchissement macOS.

## Données : pas de migration des notes

`NoteWidgetPublisher` fabrique une projection des seules notes autorisées
dans `widget-notes.json`, dans le conteneur App Group. L'autorisation est une
liste d'UUID dans les préférences ; elle est vide par défaut.

L'extension ne compile ni n'instancie `NoteStorage`, ne lit jamais
`~/Documents/PKbrain/Notes`, et ne peut ni modifier ni supprimer les originaux.
Les identifiants, titres, textes et couleurs de la projection sont les seules
données partagées. Aucun accès réseau du widget, aucun contenu dans ses logs.

## Build WidgetKit explicite

Prérequis : Xcode complet sélectionné (`DEVELOPER_DIR` possible), `xcodegen`,
identité de signature commune, App Group autorisé pour l'app
`io.github.mondary.pkbrain` et l'extension `io.github.mondary.pkbrain.widgets`.
Un certificat seul ne prouve pas que les capacités sont provisionnées.
Pour un groupe `group.*`, fournir aussi le profil de l'app via
`PK_WIDGET_HOST_PROFILE` ; le profil de l'extension doit être disponible à Xcode.
Ne pas stocker certificats, clés ou profils dans le dépôt.

```sh
# Les valeurs ci-dessous sont à renseigner avec les capacités Apple réelles.
export PK_WIDGET_TEAM="VOTRE_TEAM_ID"
export PK_WIDGET_APP_GROUP="VOTRE_APP_GROUP_AUTORISE"
export PK_WIDGET_SIGN_IDENTITY="VOTRE_IDENTITE_DE_SIGNATURE"
export PK_WIDGET_HOST_PROFILE="/chemin/local/vers/le/profil.provisionprofile"
PK_WIDGETS_ENABLED=1 bash scripts/build_macos.sh --build-only
```

Ou intégrer l'extension à un bundle déjà construit :

```sh
bash scripts/embed_widgets.sh "$PWD/releases/PKbrain.app"
```

Le script génère le projet Xcode depuis `packaging/widgets/project.yml`,
construit l'extension avec les métadonnées App Intents, l'embarque, ajoute
l'identifiant App Group au plist de l'hôte et signe de l'intérieur vers
l'extérieur. Sans les prérequis, il échoue clairement, sans lancer l'app.
Le mode standard n'ajoute aucune extension factice.

### Sans Xcode local : CI puis signature locale

La CI conserve `PKbrainWidgets-unsigned` (ZIP de l'extension avec ses
métadonnées App Intents). Télécharger l'artefact du **commit vérifié**, le
décompresser dans un dossier de build, puis :

```sh
export PK_WIDGET_TEAM="VOTRE_TEAM_ID"
export PK_WIDGET_APP_GROUP="$PK_WIDGET_TEAM.io.github.mondary.pkbrain.widgets"
export PK_WIDGET_SIGN_IDENTITY="VOTRE_IDENTITE_DE_SIGNATURE"
PK_WIDGET_PREBUILT_DIR="/chemin/PKbrainWidgets.appex" \
  bash scripts/embed_widgets.sh "$PWD/releases/PKbrain.app"
```

La convention macOS `<Team ID>.<nom du groupe>` est documentée par Apple et
vérifiée par la signature de l'équipe, contrairement aux groupes `group.*`
qui nécessitent des profils. Le script contrôle l'identifiant de l'extension
et le Team ID de la signature. Les clés privées restent dans le trousseau
local ; aucun certificat privé ou profil n'est envoyé à la CI.

Source : [Configuration des App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups).

La CI `widget-checks.yml` construit également l'extension sans signature.
Cela valide le build et les métadonnées, pas l'installation chez l'utilisateur.

## Validation sans toucher à la session utilisateur

```sh
bash scripts/check_features.sh
```

Après intégration, vérifier la présence de l'extension et l'accès au conteneur
partagé sans ouvrir de fenêtre ni charger les notes :

```sh
/Applications/PKbrain.app/Contents/MacOS/PKbrain --widget-status
```

10 vérifications : arrêt des animations selon la visibilité et Réduire les
animations, périodicité de l’onde, hauteur nulle du bandeau masqué, partage vide
par défaut, liste d'autorisation, exclusion des archives et des notes absentes,
UUID/lien, couleurs des thèmes, écriture atomique/révocation et original intact,
fichiers corrompus/schéma inconnu. Toutes les données sont fictives.

Un test de layout SwiftUI reproduit l’ancienne marge transparente de 5 pt, puis
vérifie le fond pleine hauteur et l’alignement en haut sur les trois modes de
bandeau, à deux hauteurs. Il instancie uniquement des `NSHostingView`, sans
fenêtre, capture ni interaction avec la session. Cela ne remplace pas la
validation visuelle du drawer sous la barre de menus sur un écran réel.

Recette manuelle après configuration de la signature : ajouter deux widgets
avec deux notes différentes ; modifier/renommer une note ; retirer son
autorisation ; archiver puis restaurer ; supprimer ; quitter l'app ; vérifier
petit/moyen/grand et clair/sombre. Ne pas déclarer cette recette validée sans
test dans la galerie.
