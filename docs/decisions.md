# Journal des décisions

Les choix structurants du projet, avec leur raison. Une décision remplacée reste dans le journal, marquée comme telle.

## D1 · Une app neuve, indépendante (24 octobre 2026)

Ultra HFR est écrite de zéro, dans un dépôt public, sans lien avec les apps existantes (HFR+, Super HFR+, HFRnow). Aucune ligne de code n'en est reprise : ces dépôts n'ont pas de licence. On n'en garde que la connaissance du fonctionnement de HFR, documentée dans `docs/`.

## D2 · Licence MPL-2.0

- **Pourquoi elle** : les fichiers modifiés restent ouverts, et elle est compatible avec la publication sur l'App Store (Firefox pour iOS l'utilise).
- **Pourquoi pas la GPL** : elle pose problème avec les conditions de l'App Store dès qu'il y a plusieurs contributeurs.
- **Pourquoi pas MIT** : elle permettrait une copie fermée.

## D3 · SwiftSoup, seule dépendance externe

Les analyseurs utilisent les sélecteurs CSS du HTML de HFR (`table.messagetable`, `.sujetCase3 a`, `form[name=hop]`) : le code se lit comme la page.

- **Version** : épinglée sur la branche 2.13.
- **Garde-fou** : l'essai S2 mesure la vitesse sur l'iPhone Duo. Si elle ne suffit pas, une couche sur libxml2 (fourni par iOS) la remplace derrière la même interface.

## D4 · iOS 26 minimum, Swift 6 en concurrence stricte

- **Pourquoi** : Liquid Glass, les nouvelles API SwiftUI et l'iPhone Duo.
- **Isolation** : l'app est isolée sur le fil principal par défaut, les paquets exposent des types `Sendable`.

## D5 · Corps des messages dans une vue web, avec notre HTML

Comme le prévoit la maquette « Le Fil », le corps des messages est rendu dans une vue web. Ce n'est pas le HTML de HFR :

1. chaque message est d'abord transformé en arbre (`HFRContent`) ;
2. cet arbre est rendu avec notre gabarit et `post.css`.

Le même arbre sert à la recherche dans un sujet, à l'aperçu de l'éditeur, au hors-ligne et aux widgets.

## D6 · Pages préchargées sans session

Charger une page de sujet avec sa session avance le drapeau HFR jusqu'au dernier message de cette page.

- La page que l'on lit est chargée avec la session.
- Les pages préchargées (suivante, précédente, hors ligne, recherche) le sont sans.
- Quand une page préchargée devient celle que l'on lit, on la recharge avec la session.

## D7 · Corpus de test anonymisé et publié

Les analyseurs sont testés sur de vraies pages HFR.

- **Anonymisation** : les pages sont anonymisées avant publication (textes des messages, pseudos, smileys persos, profils, images), avec un sel secret. Même pseudo → même remplaçant dans tout le corpus.
- **Pages brutes** : elles ne quittent pas la machine qui les télécharge.
