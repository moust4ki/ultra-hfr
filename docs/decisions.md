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

## D8 · Lecture hors ligne : seulement ce qui a été lu

Les pages de sujets et de listes déjà affichées sont gardées sur l'appareil (compressées, 400 au plus, dans les caches d'iOS qui peut les vider).

- **Rien n'est téléchargé pour le hors-ligne** : pas de préchargement de sujets entiers, pour rester poli avec HFR.
- **Sans connexion**, l'app montre la copie gardée avec sa date (« Hors ligne · copie de 01:25 »).
- **Les profils ne sont pas gardés** : ils contiennent des données personnelles.

## D9 · Position de lecture : elle n'avance que vers l'avant

Sans compte, l'app retient sur l'appareil le dernier message lu de chaque sujet : celui qui a passé le milieu de l'écran.

- **Comme un drapeau HFR**, elle n'avance que vers l'avant : relire une vieille page ou ouvrir un résultat de recherche ne fait pas perdre les nouveaux messages.
- **À l'ouverture** depuis une liste ou le Fil, le sujet s'ouvre sur ce message, suivi du repère « Nouveau ».
- **Avec un compte** (lot 1), le drapeau de HFR prendra le relais ; la position locale restera la référence hors ligne.

## D10 · Recherches : une requête à la validation, jamais à la frappe

La recherche sur le forum, la recherche dans un sujet et la recherche de smileys n'envoient une requête que lorsque l'on valide. Pendant la frappe, l'app ne cherche que dans ce qu'elle sait déjà (forums, sujets lus). Les résultats suivants d'un sujet se demandent avec un bouton, jamais automatiquement ; une liste filtrée ne charge pas non plus ses pages suivantes toute seule.

## D11 · Le Fil sans compte : ce que l'appareil sait déjà

Sans compte, le Fil ne peut pas lister les drapeaux. Il montre ce que l'appareil sait :

- **la reprise** de la dernière lecture et les sujets lus récemment ;
- **leurs nouvelles pages** (« +4 p. »), apprises des listes de sujets que l'on parcourt : aucune page n'est demandée à HFR pour le Fil ;
- **les Alertes Qualitay**, qui viennent d'un flux public ;
- **« Depuis ta visite de … »**, l'heure à laquelle l'app a été quittée.

Avec un compte (lot 1), les drapeaux de HFR viendront s'ajouter à cette base.
