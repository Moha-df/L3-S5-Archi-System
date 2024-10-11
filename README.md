# Exercices de TP - ASE

Ce dépôt contient des exercices pratiques autour des notions vues en
cours d'Architecture des Systèmes d'Exploitation (assembleur Zorglub33,
mécanismes de synchronisation et partage de la mémoire).

En outre, il contient quelques petis exercices (chapitre 0) pour
vérifier que vous maîtrisez bien quelques notions de C figurant dans
les prérequis du cours.

Chaque répertoire contient :

  - un fichier `Makefile`, faisant référence à ``../Makefile.inc``
    pour vous faciliter la compilation
  - un fichier `enonce.pdf` contenant l'énoncé de l'exercice
  - un ou plusieurs sources C ou assembleur contenant le ou les
    squelettes des programmes à rédiger
  - idéalement un fichier `test.sh` contenant le script de test

Ce dépôt est destiné à être « cloné » chez vous. Pensez à y intégrer
de temps à autre les modifications éventuelles de ce dépôt d'origine.

## Utiliser ce dépôt

Ce dépôt est créé spécialement pour vous pendant la durée de
l'enseignement.

L'intérêt de fournir les exercices sous forme d'un dépôt est
multiple :

  - cela vous permet de sauvegarder vos travaux sur un serveur
    maintenu par l'université : vous ne risquez pas de perdre
    ce que vous avez fait
  - vous pouvez accéder au dépôt depuis n'importe quel ordinateur
    et récupérer aisément vos fichiers
  - lorsque vous interagissez avec vos enseignants, ceux-ci
    peuvent voir vos modifications et ainsi vous répondre de
    manière appropriée
  - votre dépôt sera mis à jour si des modifications sont apportées
    aux exercices

Pour en profiter au maximum :

  - faites régulièrement des `git commit` et des `git push` pour
    mettre à jour votre dépôt : ne laissez pas une grande quantité
    de modifications en plan, vous ne saurez plus où vous en êtes
  - en particulier, avant toute interaction avec l'équipe enseignante,
    mettez à jour le dépôt
  - rédigez des messages de commit clairs et détaillés
  - minimisez les différences afin de ne pas polluer le dépôt
    avec des modifications inutiles (par exemple : ajout d'espaces
    ou de lignes vides)
  - n'ajoutez pas de fichiers exécutables, binaires ou autres
    sous-produits de la compilation
  - ne cherchez pas à gérer de multiples branches

Vous pouvez également consulter le résultat des tests en ligne,
en vous rendant sur :
    https://l3ase.pages.unistra.fr/_votre-nom-de-login_

## Scripts de test

La plupart des exercices sont fournis avec un script de test (fichier
`test.sh` dans chaque répertoire). Il est possible de les lancer :

  - soit avec : `make test`
  - soit avec : `./test.sh`

Si tout se passe bien, le script doit afficher « `Tests ok` » à la fin.

Dans le cas contraire, le nom du test échoué s'affiche. Il faut
alors :

- lire (et comprendre) le script
- examiner les fichiers laissés dans `/tmp/test*`

Les scripts de test ont été vérifiés sur la machine turing.unistra.fr.
En cas de doute, utilisez cette machine pour tester vos programmes.

### Options des scripts de test

Par défaut, les scripts exécutent tous les tests. Il est toutefois
possible d'exécuter spécifiquement un ou plusieurs tests en les
précisant sur la ligne de commande. Par exemple, pour lancer les tests
2.3 et 4.1 uniquement, il faut utiliser :

    ./test.sh 2.3 4.1

Il est de plus possible d'afficher toutes les instructions
exécutées lors d'un test avec l'option **-v**.
Par exemple, pour afficher le détail du test 1.2, il faut faire :

    ./test.sh -v 1.2

Toutes les commandes exécutées par le test (ou les tests s'il y en
a plusieurs) sont alors affichées et vous pouvez les rejouer « à la
main » pour en voir le résultat au fur et à mesure.

Normalement, les fichiers générés dans /tmp lors d'un test sont
conservés si le test échoue, et sont supprimés si le test réussit.
L'option **-k** conserve les fichiers générés par le dernier test
exécuté même s'il réussit. Vous pouvez ainsi examiner leur contenu.
Par exemple, pour conserver les fichiers créés par le test 3.1,
il faut faire :

    ./test.sh -k 3.1

Ces options peuvent naturellement être combinées :

    ./test.sh -v -k 2.3 3.1
    ./test.sh -vk 2.3 3.1

Enfin, l'option **-d** affiche la durée maximum (en secondes) que devrait
prendre l'ensemble des tests (ou la somme des tests sélectionnés).

## Rappel de langage C : la compilation conditionnelle

La compilation conditionnelle est utilisée dans certains
exercices. Petit rappel de C :

  - Le pré-processeur C permet d'inclure ou d'exclure certaines parties
    de code selon qu'un symbole est défini. Par exemple, si le code
    est :

        #if defined(VERROUILLAGE)              // ou bien : #ifdef VERROUILLAGE
            TCHK (pthread_mutex_lock (&m));
            n++ ;
            TCHK (pthread_mutex_unlock (&m));
        #else
            n++ ;
        #endif

    le compilateur verra trois lignes (l'incrémentation entourée de
    `lock`/`unlock`) si et seulement si le symbole `VERROUILLAGE` est
    défini. Dans le cas contraire, il verra la deuxième version,
    contenant une seule ligne (l'incrémentation).

  - Le symbole testé avec `defined()` est un symbole du pré-processeur,
    et *pas* une variable normale. Un tel symbole peut être défini de
    deux façons :

    1.  soit comme une constante dans le fichier, par une ligne de la
        forme :

            #define VERROUILLAGE

        (avec ou sans valeur), placée *avant* les directives
        `#if`/`#else`/`#endif` ;

    2.  soit être défini à l'appel du compilateur, avec l'option `-D`,
        de la façon suivante :

            cc -DVERROUILLAGE ...

    Pour la compilation conditionnelle, on utilise plus souvent la
    seconde forme, et on ne donne pas de valeur au symbole (il ne sert
    qu'à sélectionner des parties de code).

  - On peut de cette façon produire facilement deux versions différentes
    selon les options de la commande de compilation, voire même deux
    programmes différents. Par exemple, les commandes :

        cc ... -o prog
        cc -DVERROUILLAGE ... -o progverr

    produisent deux exécutables : `prog` n'utilise pas *lock*/*unlock*,
    `progv` les utilise ;

-   Quelques remarques finales :

    -   les lignes `#if`/etc. ne doivent pas contenir d'autre code (mais
        éventuellement un commentaire) ;
    -   la partie `#else` est optionnelle, mais la ligne `#endif` est
        obligatoire ;
    -   on peut imbriquer les `#if`/`#else`/`#endif` (mais c'est vite
        difficile à lire) ;
    -   il existe une directive `#elif ...` pour les cascades de tests
        (cela évite souvent l'imbrication), les conditions de
        `#if`/`#elif` peuvent être complexes, etc. (lisez la
        documentation du pré-processeur) ;
    -   le code à l'intérieur des directives doit toujours être du C
        correct (il sera lu par le pré-processeur) ; on ne peut pas
        utiliser ces directives pour des commentaires (on utilise
        `/*...*/` pour cela) ;
    -   utilisez ce mécanisme avec parcimonie, documentez les symboles
        qui changent le contenu du programme, ainsi que les fichiers
        `Makefile` qui utilisent ces symboles ; les erreurs liées à la
        compilation conditionnelle sont *souvent* difficiles à détecter
        et corriger ;
    -   à titre d'exemple, lisez le manuel de la fonction `assert()`,
        qui utilise le symbole `NDEBUG` pour devenir inerte ; vous
        pouvez aussi consulter les fichiers dans le répertoire
        `/usr/include`.


## Utiliser le débogueur pour localiser un blocage

Il peut arriver que vos programmes se bloquent suite à une
synchronisation malheureuse. Le débogueur `gdb` peut vous aider à
localiser sans effort l'endroit où le problème se situe et en comprendre
l'origine.

La première chose à faire est de compiler le programme avec l'option
`-g`.  Heureusement, tous les exercices du dépôt sont compilés avec
cette option.

Supposons que votre programme s'appelle `a.out` :

- s'il n'a pas encore démarré, démarrez-le avec `gdb` :

    `gdb a.out`

  puis `run`, avec les arguments du programme. Laissez-le progresser
  jusqu'au blocage, puis appuyez sur `^C` pour indiquer à `gdb` de
  reprendre le contrôle.

- s'il a déjà démarré et qu'il est bloqué, ouvrez une autre fenêtre,
  cherchez son numéro de processus (pid, supposons que ce soit 1234)
  puis lancez `gdb` :

    `gdb a.out 1234`

  Votre programme est maintenant sous le contrôle de `gdb`

Dès lors, vous pouvez utiliser les commandes :

  - `info threads` : pour voir les différents threads
  - `thread 2` : pour basculer dans l'environnement du thread 2
  - `where` : pour voir l'empilement des appels de fonctions du thread courant
  - `up` ou `down` : pour vous déplacer dans les appels de fonctions

L'empilement des appels de fonctions comprend des fonctions de
bibliothèque dont le source n'est pas accessible à `gdb`. Il faut se
déplacer (avec `up`) pour retrouver l'endroit où vous avez appelé
la fonction bloquante. Là, vous pouvez consulter les arguments et les
variables pour comprendre ce qui a conduit au blocage.
