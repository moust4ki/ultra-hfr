# Ultra HFR

Client iOS libre et non officiel de [forum.hardware.fr](https://forum.hardware.fr) (HFR), pour iPhone, iPhone Duo et iPad.

> **État : lot 0, essais.** L'app se lit déjà sans compte ; la connexion est prête à être essayée, l'envoi de messages viendra au lot 1. Pas encore de version publique à installer.

## Ce qui marche déjà, sans compte

- **Forums et listes de sujets** : catégories, sous-forums, épinglés repliés, sujets non lus calculés sur l'appareil, filtre « Non lus ».
- **Lecture continue** : pages enchaînées, curseur de pages, « Aller à la page », repère « Nouveau », sondages, spoilers, vidéos, visionneuse d'images, liens HFR ouverts dans l'app.
- **Citer** : glisser un message pour l'ajouter à la multi-citation, menu natif « ••• » de chaque message.
- **Rédaction** (sans envoi) : BBCode, aperçu exact, smileys HFR et recherche de smileys persos, brouillons gardés sur l'appareil.
- **Recherche** sur le forum (titres, contenu) et **dans un sujet** (mot, pseudo, depuis la page lue), résultat surligné dans la lecture.
- **Profils** des membres, **Alertes Qualitay**, **lecture hors ligne** des pages déjà lues.
- **Réglages** : thème clair, sombre ou noir OLED, huit couleurs, messages compacts, signatures, taille des smileys ; Dynamic Type jusqu'aux tailles d'accessibilité.
- **iPhone, iPhone Duo plié et déplié, iPad** : onglets en largeur compacte, colonne et lecture côte à côte en largeur régulière.

## Ce que sera l'app

Une app pensée pour les habitués de HFR, qui suivent des dizaines de sujets et lisent plusieurs fois par jour :

- **Le Fil** : ce qui a bougé depuis ta dernière visite (sujets suivis, MP, Alertes Qualitay) ; une carte pour reprendre la lecture interrompue.
- **Une lecture continue** : un sujet s'ouvre au premier message non lu, les pages s'enchaînent en défilant, un curseur permet de sauter à n'importe quelle page.
- **Glisser pour citer**, multi-citation, éditeur BBCode avec aperçu exact, smileys HFR et persos.
- Tout HFR : forums, drapeaux et favoris, messages privés, sondages, recherche, profils, Alertes Qualitay, liste noire, plusieurs comptes.
- Conçue pour iOS 26 : Liquid Glass, Dynamic Type, VoiceOver, thèmes clair, sombre et noir OLED, iPhone Duo plié et déplié, iPad.

## Principes

- **Natif** : Swift 6 en concurrence stricte, SwiftUI, iOS 26 minimum. Le corps des messages est affiché dans une vue web, avec notre propre HTML.
- **HFR n'a pas d'API.** L'app lit les pages HTML du forum et remplit ses formulaires, comme un navigateur. Tout ce qui parle à HFR est isolé dans `HFRKit` et testé sur un corpus de vraies pages, anonymisées.
- **Respect du forum.** Un User-Agent qui nomme l'app, deux requêtes simultanées au plus, pas d'aspiration de sujets. Les pages préchargées le sont sans session, pour ne jamais avancer tes drapeaux à ta place.
- **Rien d'inventé.** L'app n'affiche que ce que HFR fournit, plus ce qu'elle calcule sur ton appareil (dernière visite, position de lecture, brouillons).

## Organisation

| Dossier | Contenu |
|---|---|
| `UltraHFR/` | L'app : écrans, navigation |
| `Packages/UltraHFRKit/` | Le cœur, en paquets Swift testables sans l'app |
| `↳ HFRKit` | Réseau, comptes, formulaires, lecture des pages HFR |
| `↳ HFRContent` | Le contenu d'un message sous forme d'arbre, BBCode |
| `↳ HFRReader` | Le HTML, les styles et le script de la vue de lecture |
| `↳ HFRDesign` | Couleurs, thèmes et composants de la maquette « Le Fil » |
| `Scripts/` | Téléchargement et anonymisation du corpus de pages |
| `docs/` | Décisions et documentation du protocole HFR |

## Compiler

- Xcode 27, iOS 26 minimum.
- Ouvre `UltraHFR.xcodeproj` et lance le schéma **UltraHFR**.
- Pour installer sur ton appareil, crée `Config/Local.xcconfig` (ignoré par git) :

  ```
  DEVELOPMENT_TEAM = TONEQUIPE
  ULTRAHFR_BUNDLE_ID = com.exemple.ultrahfr
  ```

- Tests du cœur, sans simulateur :

  ```bash
  cd Packages/UltraHFRKit && swift test
  ```

- Le projet Xcode est décrit dans `project.yml`. Après une modification des cibles : `xcodegen generate`.

## Corpus de pages de test

Les analyseurs sont testés sur de vraies pages HFR publiques, téléchargées par `Scripts/capture-corpus.sh` puis anonymisées par `Scripts/anonymiser-corpus.swift` :

- **Remplacés** : les textes des messages, les pseudos, les smileys persos, les numéros de profil et les adresses des images.
- **Gardé intact** : la structure HTML, à la balise près.

Les pages brutes restent sur la machine de celui qui les télécharge (`Corpus/raw/`, ignoré par git). Seules les pages anonymisées sont publiées.

## Licence

[Mozilla Public License 2.0](LICENSE).

- Tu peux utiliser, modifier et redistribuer le code, y compris dans une app publiée sur l'App Store.
- Les fichiers modifiés restent sous la même licence et donc ouverts.

Ultra HFR n'est ni affilié à hardware.fr ni approuvé par lui.
