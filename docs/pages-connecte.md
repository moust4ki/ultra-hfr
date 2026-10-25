# Pages vues connecté

Constats faits le 25 octobre 2026 sur de vraies pages chargées avec un compte (corpus `connecte-*`, anonymisé). Ils servent au lot 1 (lecture avec le compte).

## « Mes drapeaux » (`/forum1f.php?config=hfr.inc&owntopic=1`)

- La page ne liste que les sujets suivis **qui ont du nouveau**. Un sujet suivi absent de la page est lu jusqu'au bout.
- Les sujets sont groupés par catégorie : une ligne `tr.fondForum1fCat` par catégorie, dont le lien `a.cHeader` mène à `forum1.php?…&cat=N`. Une catégorie où tout est lu garde son en-tête, sans ligne.
- `owntopic=3` : les favoris (étoile) seuls, même présentation.
- L'en-tête de catégorie contient un lien `suppressflag.php?id_user=…&codehex=…` qui efface les drapeaux de la catégorie : à ne jamais appeler sans action explicite du membre.

## Listes de sujets vues connecté

- La colonne `sujetCase5` porte le drapeau du membre (`flag0.gif` rouge, `flag1.gif` bleu, `favoris.gif` étoile) et le lien vers l'endroit où il s'est arrêté.
- L'icône de la colonne `sujetCase1` (`closedb_new.gif` « On », `closed.gif` « Off ») ne dit pas si un sujet suivi est lu : tous les sujets sont « On » pour un visiteur, et les sujets de « Mes drapeaux » aussi. Le seul signal fiable est la présence dans « Mes drapeaux ».

## MP

- Liste : `/forum1.php?config=hfr.inc&cat=prive&page=1`, mêmes lignes qu'une liste de sujets, avec une colonne de plus (`td.sujetCase2` « ignorer »).
- Un nouveau message pour le membre se voit à l'icône de la première colonne (`alt="On"`, infobulle « Nouveau message »), comme dans une liste de sujets ; « Pas de nouveau message » sinon.
- `<span class="red">[non lu]</span>` devant le titre ne veut **pas** dire non lu pour le membre : l'infobulle dit « Ce message n'a pas été lu par : … ». C'est le correspondant qui n'a pas encore lu le dernier message.
- Aucune page vue ne portait de bandeau « nouveau message privé » quand il n'y en avait pas ; à vérifier quand il y en aura un.
- Une conversation est une page `forum2.php?…&cat=prive&post=N` : `cat` n'est pas un nombre, l'analyseur de sujet devra l'accepter.

## Formulaires de réponse (`/message.php?config=hfr.inc&cat=…&post=…`)

- Formulaire `form#hop`, envoyé à `/bddpost.php` ; champs `content_form`, `hash_check`, `post`, `cat`, `sujet`, `pseudo`.
- Les derniers messages du sujet ou du MP sont affichés sous le formulaire, dans des lignes `td.messCase1bis` (auteur) + cellule de texte, hors des blocs `div id="para…"`.

## Données personnelles dans ces pages

Au-delà des pseudos et des textes, ces pages contiennent : le jeton `hash_check`, le jeton `codehex`, le numéro de membre (`id_user=`, nom du fichier d'avatar `mesdiscussions-N.jpg`, `_smilies_timer('hfr.inc',N)`) et le pseudo du membre dans le champ `pseudo` des formulaires. `Scripts/anonymiser-corpus.swift` les brouille tous ; une page vue connecté se reconnaît à son `hash_check` rempli.
