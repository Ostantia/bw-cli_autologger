# Biswarden CLI Autologger

Ce projet entièrement écrit en Bash permet d'utiliser Bitwarden CLI pour se connecter automatiquement à vos différentes identitiés et pouvoir ainsi les utiliser au travers du terminal.

## Sommaire

- [Biswarden CLI Autologger](#biswarden-cli-autologger)
  - [Sommaire](#sommaire)
  - [Avantages de cet utilitaire (pouquoi l'utiliser)](#avantages-de-cet-utilitaire-pouquoi-lutiliser)
  - [Installation](#installation)
    - [Paquets prérequis](#paquets-prérequis)
    - [Manipulations lors de l'installation](#manipulations-lors-de-linstallation)
  - [Configuration](#configuration)
    - [Paramètres de base](#paramètres-de-base)
    - [Ajout de clés SSH](#ajout-de-clés-ssh)
      - [Utilisation de SSH Agent et limitations](#utilisation-de-ssh-agent-et-limitations)
      - [Utilisation de SSH configs](#utilisation-de-ssh-configs)
    - [Ajout de mots de passes](#ajout-de-mots-de-passes)
    - [Ajout de configurations, scripts et fichiers synchronisés](#ajout-de-configurations-scripts-et-fichiers-synchronisés)
    - [Fonction de déconnexion](#fonction-de-déconnexion)
  - [Utilisation du script et authentification automatique](#utilisation-du-script-et-authentification-automatique)
    - [Utilisation de l'authentification dans de multiples TTY sans ré-authentification](#utilisation-de-lauthentification-dans-de-multiples-tty-sans-ré-authentification)
    - [Installation sur une autre machine après la première configuration](#installation-sur-une-autre-machine-après-la-première-configuration)
    - [Connexion aux hôtes SSH configurés dans le fichier config](#connexion-aux-hôtes-ssh-configurés-dans-le-fichier-config)
    - [Connexion aux hôtes SSH NON configurés](#connexion-aux-hôtes-ssh-non-configurés)
    - [Nouvelle tentative de connexion après échec](#nouvelle-tentative-de-connexion-après-échec)
    - [Déconnexion automatisée et déconnexion manuelle, les différences](#déconnexion-automatisée-et-déconnexion-manuelle-les-différences)
      - [Déconnexion par fermeture des tty](#déconnexion-par-fermeture-des-tty)
      - [Déconnexion par la fonction identities\_destroy](#déconnexion-par-la-fonction-identities_destroy)
  - [Remerciements](#remerciements)

## Avantages de cet utilitaire (pouquoi l'utiliser)

Bitwarden CLI Autologger vous permettra de toujours avoir vos identifians, mots de passes, configurations et clés SSH automatiqueemnt disponibles et ce de la façon la plus sécurisée possible.

> *Pour plus de détails concernant l'authentification automatisée, consultez la partie "Utilisation de l'authentification dans de multiples TTY sans ré-authentification" de la documentation.*

Un avantage également indéniable : Vous aurez toujours accès à la toute dernière version disponible sur votre Instance Bitwarden des différents mots de passes et configurations. Cela est assuré grâce à un job en tache de fond qui effectue une mise à jour de la base locale de Bitwarden CLI toutes les 10 secondes.

De plus, grâce à cet utilitaire, vous ne serez jamais dépaysé : tout les terminaux l'utilisant bénéficieront de la même configuration partout ou cet utilitaire sera installé. Une fois configuré pour la première fois, il vous suffira de recopier la même configuration de base dans tout vos fichier .bashrc et tout sera automatiqueemnt synchronisé !

## Installation

Installer Bitwarden CLI Autologger peut se faire sur tout OS Linux et MacOS utilisant Bash. (Je ne supporterai pas Windows, les principes de fonctionnement n'étant pas du tout les mêmes, et je n'aime pas PowerShell :P)

### Paquets prérequis

Les paquets indispensables pour le bon fonctionnement de ce projet sont :

- Bitwarden CLI : Téléchargez le binaire correspondant à votre situation ici : <https://bitwarden.com/fr-fr/help/cli/>
- jq : Paquet permettant de parser du JSON, format natif de Bitwarden CLI. Ce dernier est disponible dans tout les repositories des installations de Linux.
- Bash : Oui, ce projet est en bash uniquement. Il peut être compatible avec d'autres Shell supportant SH mais je n'en garantis pas le support. Cependant, si vous l'utilisez en tant que script et l'appelez avec la commande bash, il devrait pouvoir fonctionner dans tout les SHells.
- git : Pour télécharger ce projet et le mettre à jour si nécessaire.
- wget : Pour récupérer le binaire de Bitwarden CLI depuis le site de Bitwarden.
- tmux/screen : Ces multiplexeurs sont indispendables car ils permettent d'hériter des configurations (notamment de la variable de session) depuis la session parente les ayant appelés, ce qui est l'une des bases de fonctionnement de ce script.

### Manipulations lors de l'installation

Récupération de Bitwarden CLI et installation (exemple pour une version Linux) :

```bash
sudo su -l root
cd /tmp/.
wget -O "bw.zip" "https://vault.bitwarden.com/download/?app=cli&platform=linux"
unzip bw.zip
mv bw /usr/bin/.
chmod 755 /usr/bin/bw
chown root: /usr/bin/bw
exit
```

Une fois ces actions en root effectuées, vous pouvez procéder pour le reste des étapes sans le root.
Si il ne vous est pas possible de passer root, vous pouvez toujours placer ce binaire dans votre répertoire utilisateur, puis mettre à jour votre variable d'environnement **"PASS"** pour qu'elle intègre ce binaire dans vos commandes disponibles.

Notez que cette méthode ne rendra le binaire disponible que pour votre utilisateur courant.

Mise en place de la base de Bitwarden CLI Autologger :

```bash
cd /tmp/.
git clone https://gitea.cloudyfy.fr/Siphonight/bw-cli_autologger.git
cd bw-cli_autologger
cat bw_cli_autolog.sh >> ~/.bashrc
```

Avec cela, vous avez désormais la base du bitwarden autologger.

Il faudra cependant configurer ce dernier pour qu'il soit utilisable.

## Configuration

### Paramètres de base

Afin de pouvoir commencer l'utilisation de ce script chardé dans le bashrc, vous devez renseigner les deux variables présentes dans la fonction **"identities_create"** :

- "Bitwarden_Email" : Entrez ici votre adresse email utilisée sur l'instance bitwarden afin de vous y connecter.
- "Bitwarden_Server" : Entrez ici l'URL complète du serveur auquel le script devra se connecter.

Exemples d'URL de serveur Bitwarden :

- URL du serveur officiel US : <https://vault.bitwarden.com>
- URL du serveur officiel EU : <https://vault.bitwarden.eu>

Je vous recommande également, pour ce script ainsi que pour le reste des fichiers et configurations que vous souhaitez utiliser avec Bitwarden CLI Autologger de tous les placer dans votre coffre Bitwarden en tant que notes sécurisées.

Vous pourrez par la suite les utiliser pour la synchronisation en suivant les différents chapitres de cette documentation.

Cela vous permettra d'avoir une synchronisation totale entre vos différents terminaux, même sur des machines séparées.

Enfin, créez dans votre instance bitwarden une note sécurisée appelée **"identities - configs"**.

Cette étape est importante et vous permettra de configurer Bitwarden CLI Autologger.

### Ajout de clés SSH

L'une des fonctionalités les plus intéressantes de Bitwarden CLI Autologger, c'est de pouvoir gérer des clés SSH automatiquement et de façon à ce qu'elles soient éphèmères et ne touchent jamais le disque.

Plusieurs configurations sont possibles pour arriver à ce résultat, je détaille ces dernières dans les sous parties ci dessous.

#### Utilisation de SSH Agent et limitations

La façon la plus sécurisée de gérer les clés SSH de connexion et authentification sur les machines distantes est l'agent SSH.

La méthode que je vais présenter ici n'est valable que si vous avez **exactement 3 clés SSH ou moins en tout.**

> *Cette limitation est due aux configurations de base des serveurs SSH du monde entier.*
>
> *Ces derniers n'acceptent que 3 tentatives d'authentification par clés pour chaque connexion.*
>
> *Utiliser l'agent SSH uniquement dans configurations complémentaires fait que les clés seront essayées dans leur ordre d'ajout au socket de l'agent, une par une jusqu'à réussite de l'authentification, ou ttimeout de l'hôte distant. Si la bonne clé est de ce fait en 4ème position, l'authentification par cette méthode échouera toujours.*

Pour utiliser cette méthode, vous devez ajouter les clés SSH que vous souhaitez utiliser au travers de ce script dans des notes sécurisées (séparées de préférence).

Retenez bien le nom de la note sécurisée créée, nous allons la réutiliser plus tard.

Dans le contenu de cette note, mettez uniquement la clé SSH, sans retour à la ligne supplémentaire ou espace.

Ensuite, allez modifier la note sécurisée créée précédemment et nommée **"identities - configs"** et ajoutez la ligne suivante :

```bash
echo "$BW_List" | jq -r '.[] | select(.name=="<NOM_DE_LA_NOTE_CONTENANT_LA_CLE>") | .notes' | ssh-add -
```

Répetez ces étapes pour chaque clé SSH que vous souhaitez ajouter à l'agent.

Une fois fait, pensez à bien enregistrer vos modifications sur les notes dans Bitwarden, et testez votre nouvelle configuration en utilisant la commande ci dessous (Ou ouvrez une nouvelle session dans le multiplexeur) :

```bash
source ~/.bashrc
```

Vous devriez normalement voir apparaitre l'ajout de vos clés ainsi que l'ouverture du socker de l'agent SSH :

```text
Bitwarden connecté, mise en place des identités...
Agent pid 25158
Identity added: (stdin) (test1)
Identity added: (stdin) (siphonight@Alicee)
Identity added: (stdin) (test2)
siphonight@Alicee:~$
```

Si vous obtenez ce résultat, la configuration est désormais fonctionnelle.

Dans le cas contraire, il est plus facile de trouver le problème grâce aux messages d'erreurs envoyés par Bitwarden CLI. (Souvent des erreurs dans la syntaxte.)

#### Utilisation de SSH configs

Si vous avez plus que 3 clés SSH à ajouter dans Bitwarden CLI Autologger, la méthode utilisant uniquement l'agent SSH ne pourra pas fonctionner.

Il faudra alors ajouter des étapes complémentaires à la configuration afin que celle ci soit fonctionnelle.

Tout d'abord, effectuez les étapes de configuration de l'agent SSH présentées dans la partie précédente, mais avec un ajustement : Ajoutez également des notes séparées contenant les clés publiques correspondantes à chaque clé SSH privée ajoutée, mais pour ces dernières n'effectuez pas la modification de la note sécurisée **"identities - configs"**.

Ensuite, modifiez votre note sécurisée **"identities - configs"** en ajoutant les lignes ci dessous pour chaque clé SSH publique :

```bash
echo "$BW_List" | jq -r '.[] | select(.name=="<NOM_DE_LA_NOTE_CONTENANT_LA_CLE_PUBLIQUE>") | .notes' >"$HOME"/.ssh/<NOM_DE_LA_CLE_PUBLIQUE>.pub
```

Pas d'inquiétude, les clés publiques peuvent être révélées et ne sont pas obligatoirement secrètes.

Nous en avons besoin dans ce répertoire pour pouvoir appeler les clés privées stockées de façon sécurisée dans l'agent SSH local au travers du fichier SSH config.

Créez ensuite une nouvelle note sécurisée nommée **"identities - sshconfig"**, et ajoutez y l'une des configurations suivantes qui correspondrait à la connexion souhaitée en l'adaptant à votre cas (ce sont des exemples) :

```text
Host test1
  User siphonight
  HostName test1.example.com
  IdentityFile ~/.ssh/<NOM_DE_LA_CLE_PUBLIQUE_CORRESPONDANTE>.pub

Host test2
  User siphonight
  HostName 192.168.1.165
  IdentityFile ~/.ssh/<NOM_DE_LA_CLE_PUBLIQUE_CORRESPONDANTE>.pub

Host alicee
  User aliceinwonderland
  HostName alicee.example.com
  Port 2222
  IdentityFile ~/.ssh/<NOM_DE_LA_CLE_PUBLIQUE_CORRESPONDANTE>.pub
```

Enfin, ajoutez la ligne ci dessous dans la note sécurisée **"identities - configs"** :

```bash
echo "$BW_List" | jq -r '.[] | select(.name=="identities - sshconfig") | .notes' >"$HOME"/.ssh/config
```

Enfin, rechargez votre envrionnement (Ou ouvrez une nouvelle session dans le multiplexeur) :

```bash
source ~/.bashrc
```

Vous devriez toujours obtenir ce résultat :

```text
Bitwarden connecté, mise en place des identités...
Agent pid 25158
Identity added: (stdin) (test1)
Identity added: (stdin) (siphonight@Alicee)
Identity added: (stdin) (test2)
siphonight@Alicee:~$
```

Reghardez également le contenu de votre fichier sshconfig afin de vous assurer que son contenu est identique à la note sécurisée **"identities - sshconfig"** :

```bash
cat ~/.ssh/config
```

Puis, testez une connexion ssh directe sur un des hôtes configurés dans le fichier afin de valider le bon fonctionnement de la mise en place au global :

```bash
ssh test1
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-52-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Wed Feb 12 09:36:02 2025 from 172.19.0.8

siphonight@test1:~$
```

Si vous y parvenez, la configuration est valide. Bien joué !

### Ajout de mots de passes

Vous pouvez, en plus des clés SSH, ajouter des mots de passes et les récupérer depuis Bitwarden grâce à ce script.

Notez cependant qu'à cause de limitations techniques, ces derniers seront déclarés en tant que variables d'environnements seulement.

> *En principe, cette méthode est sécurisée.*
>
> *Si votre machine est compromise, toute action effectuée dessus l'est également par définition, et aucune sécurité ne sera efficace.*

Pour cela, ajoutez le compte/mot de passe souhaité dans votre Instance Bitwarden (Pas dasn une note sécurisée, mais dans un identifiant, comme tout autre identifiant), puis ajoutez la configuration suivante dans la note sécurisée **"identities - configs"** :

```bash
export USERNAME_<NOM_DU_COMPTE_DANS_BITWARDEN>=$(echo "$BW_List" | jq -r '.[] | select(.name=="<NOM_DU_COMPTE_DANS_BITWARDEN>") | .login.username')
export PASSWORD_<NOM_DU_COMPTE_DANS_BITWARDEN>=$(echo "$BW_List" | jq -r '.[] | select(.name=="<NOM_DU_COMPTE_DANS_BITWARDEN>") | .login.password')
```

Ensuite, rechargez votre envrionnement (Ou ouvrez une nouvelle session dans le multiplexeur) :

```bash
source ~/.bashrc
```

Vous devriez désormais pouvoir voir votre variable d'environnement ainsi que sa valeur avec la commande ci dessous :

```bash
printenv | grep USERNAME_<NOM_DU_COMPTE_DANS_BITWARDEN> ; printenv | grep PASSWORD_<NOM_DU_COMPTE_DANS_BITWARDEN>
```

Vous pouvez désormais utiliser ces identifiants dans d'autres commandes, comme par exemple **sshpass**.

### Ajout de configurations, scripts et fichiers synchronisés

Il est possible d'ajouter des scripts, des configurations et des fichiers à votre instance Bitwarden afin qu'ils soient gérés par Bitwarden Auto Logger.

Pour cela, ajouter une nouvelle note sécurisée que vous nommez comme vous le souhaitez, et mettez en contenu de la note votre script, configuration ou texte.

Ensuite, en fonction de la nature de la donnée ajoutée et de ce que vous souhaitez effectuer avec, ajoutez une ligne dans la note sécurisée **"identities - configs"** en conséquence (Ci dessous sont des exemples possibles) :

```bash
# Pour des configurations :
echo "$BW_List" | jq -r '.[] | select(.name=="Tmux configuration") | .notes' >"$HOME"/.tmux.conf
echo "$BW_List" | jq -r '.[] | select(.name=="gitconfig") | .notes' >"$HOME"/.gitconfig

# Pour des scripts :
echo "$BW_List" | jq -r '.[] | select(.name=="identities - scripts") | .notes' >"$HOME"/.identities-scripts.sh
chmod 755 "$HOME"/.additionnal.sh
source "$HOME"/.additionnal.sh
```

Ensuite, rechargez votre envrionnement (Ou ouvrez une nouvelle session dans le multiplexeur) :

```bash
source ~/.bashrc
```

Les fichiers ainsi ajoutés sont désormais présents dans votre répertoire utilisateur.

### Fonction de déconnexion

La fonction de déconnexion fournie de base est fonctionnelle et n'a pas besoin d'être modifiée dans un cas d'utilisation normal.

Cependant, ci vous souhaitez que cette dernière fasse plus que ce qu'elle ne fait déjà (comme par exemple supprimer des configurations et fichiers synchronisés, ou toute autre action), vous pouvez modifier cette dernière dans le fichier ~/.bashrc.

Par exemple, pour supprimer des fichiers à la déconnexion, ajoutez y la ligne suivante, après la ligne **"unset BW_Session"** :

```bash
rm -rf "$HOME"/.ssh/test1.pub
```

Mais sachez que toute commande bash est disponible, ajoutez y ce dont vous avez besoin et pensez à recharger votre environnement pour la mise à jour de la fonction :

```bash
source ~/.bashrc
```

## Utilisation du script et authentification automatique

Certaines utilisations et comportement du script peuvent vous paraitre étranges ou buggés.

Dans la plupart des cas ce ne sont pas des bugs mais des spécificités qui doivent être connues afin de pouvoior pleinement profiter de cet utilitaire.

Cette partie permet de décrire les plus courantes d'entre elles.

### Utilisation de l'authentification dans de multiples TTY sans ré-authentification

Ce problème ne vient que si vous utilisez Bitwarden CLI Autologger sans multiplexeur.

Cet utilitaire dépends intégralement de l'utilisation d'un programme tel que TMUX ou SCREEN, car le token d'authentification (et les autres variables d'nevironnement) sont transmis de la session parente aux sessions TMUX ouvertes depuis cette dernière.

La détection de l'authentification étant basée sur ce token, sa présence est de ce fait indispensable.

Vous pouvez, si cela n'est pas possible, utiliser le token au sein d'un fichier que vous appellerez ensuite par l'utilitaire, mais cela baisse la sécurité de l'installation et n'est pas officiellement supporté.

Pour correctement utiliser cet utilitaire et toutes ses capacités, authentifiez vous d'abord dans votre session nouvellement ouverte.

Puis, si vous utilisez TMUX, ouvrez une nouvelle session avec :

```bash
tmux new-session -n terminal
```

Vous remarquerez alors qu'une nouvelle authentification ne vous sera pas demandée.

Ce fonctionnement est également similaire dans SCREEN.

### Installation sur une autre machine après la première configuration

Une fois la première configuration effectuée (en suivant les indications de cette documentation), vous pouvez désormais simplement copier la base de l'utilitaire sans devoir reproduire toute la configuration à chaque nouvel appareil ou terminal.

> *Assurez vous cependant que les prérequis sont bien tous présents sur le terminal de destination, sinon cela ne fonctionnera pas.*

La synchronisation étant assurée au travers du coffre Bitwarden lui même, seules les fonctions essentielles sont à transférer. Le reste sera généré automatiquement.

Pour cela, depuis l'un de vos terminaux déjà configurés, copiez les fonctions **"identities_create"**, **"identities_destroy"** ainsi que la ligne finale appellant la fonction.

Collez ensuite ces dernières à la fin de votre fichier .bashrc sur un terminal non configuré, et rechargez votre environnement :

```bash
source ~/.bashrc
```

C'est tout, votre environnement est désormais synchronisé et prêt.

### Connexion aux hôtes SSH configurés dans le fichier config

Les hôtes configurés dans votre fichier .ssh/config peuvent $etre appelés directement par le nom que vous leur avez donné, sans précision du port ou de l'utilisateur si ce dernier est donné dans la configuration.

Exemple de configuration et de son utilisation :

```text
Host alicee
  User aliceinwonderland
  HostName alicee.example.com
  Port 2222
  IdentityFile ~/.ssh/<NOM_DE_LA_CLE_PUBLIQUE_CORRESPONDANTE>.pub
```

Maintenant vous pouvez vous connecter à cet hôte en tapant :

```bash
ssh alicee
```

Cela vous connectera à l'hôte configuré avec l'utlisateur configuré sur le port configuré.

A noter que vous pouvez mettre plusieurs configurations pour le même hôte.

Enfin, sachez que vous pouvez aussi tout à fait passer par une comnde ssh classique, et autre fait important : Toute application ou commande passant par SSH (ou son binaire) utilisera la configuration et bénéficiera de la connexion automatique.

> *Par cela, il est entendu que par exemple, le clonage de repository git la méthode SSH fonctionnera également soit avec les paramètres de base, soit avce le nom donné à l'hôte distant dans la configuration. Les commandes RSYNC fonctionnerons également.*
>
> *Et tout cela en utilisant les clés SSH gérées coté Bitwarden.*

Example :

```bash
ssh -p2222 aliceinwonderland@alicee.example.com
```

Dans cet exemple, je n'ai volontairement pas précisé la clé SSH, car cette dernière sera automatiquement utilisée par l'agent.

En effet, SSH va faire le rapprochement entre ces paramètres de connexion et la configuration du fichier ".ssh/config".

### Connexion aux hôtes SSH NON configurés

> *A noter que ce qui suit ne concerne que la connexion par mots de passes aux hôtes non configurés dans le fichier .ssh/config lorsque l'utilisation de clés SSH est configurée sur cet utilitaire.*
>
> *Les authentifications par clés SSH non gérées par cet utilitaire sont toujours possibles en précisant les clés SSH que vous souhaitez utiliser avec l'argument "-i" dans votre commande SSH.*

Si vous ssouhaitez vous connecter par mot de passe à un hôte non configuré au moyen du fichier .ssh/config, la connexion ne pourra qu'échouer.

Cela est dû au fait que l'agent SSH, en l'abscence de configuration détectée en provenance du fichier config vas commencer par tester toutes les clés qu'il a dans son socket une par une, mais ces dernière ne correspondrons pas et vont à terme timeout la connexion sans que vous puissiez voir le prompt du mot de passe.

Afin de pouvoir vous authentifier en mot de passe sur un hôte non configuré, vous devez ajouter quelques arguments dans votre commande SSH :

```bash
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no siphonight@test1.example.com
```

Cette commande permet de contourner l'utilisation de l'agent SSH et ainsi vous connecter.

### Nouvelle tentative de connexion après échec

Si vous échouez à vous authentifier lors de l'ouverture du terminal, les identités et synchronisations ne serrons pas synchronisées.

Afin de recommencer l'étape de synchronisation, appelez la fonction de création d'identités de l'utilitaire avec la commande ci dessous :

```bash
identities_create
```

Le prompt de connexion devrait ainsi réapparaitre et vous permettre d'effectuer une nouvelle tentative.

### Déconnexion automatisée et déconnexion manuelle, les différences

La sécurité de cet utilitaire est composée de deux types de déconnexions, très similaires mais ayant tout de même des différences dans une situation particulière.

> *Si vous n'avez pas approté de modifications à la fonction "identities_destroy" comme décrit dans la partie "Fonction de déconnexion", il n'y a pour vous aucune différence entre les deux méthodes de déconnexions.*

#### Déconnexion par fermeture des tty

Le système d'authentification de ce script étant basé sur une variable d'environnement définie dans la prmeière session ouverte ayant réussie la connexion, si vous fermez cette dernière ainsi que toutes les sessions tmux y étant associées, le token sera détruit.

Sans le token, l'utilisation de la base de données Bitwarden locale est impossible, ce qui est de facto une déconnexion.

De ce fait, fermer votre terminal équivaut à une forme de déconnexion, car les agents SSH et la connexion sont supprimés.

Cependant, tout les fichiers générés par la connexion à Bitwarden au travers de cet utilitaire ne seront pas supprimés.

Cela n'est généralement jamais un problème, mais si vous avez généré des fichiers comprenant de l'authentification ou des secrets, ces derniers seront toujours présents sur le filesystem, dans votre répertoire utilisateur.

#### Déconnexion par la fonction identities_destroy

La déconnexion en utilisant la fonction **"identities_destroy"** est la forme de déconnexion la plus sûre car elle vous permet d'utiliser ce que vous avez configuré dans cette dernière, si vous avez modifié la fonction de base.

Dans le cas ou vous n'avez pas ajouté d'actions complémentaires dans la fonction, alors il n'y a virtuellement pas de différence entre les deux méthodes de déconnexion.

<!--## Explication du fonctionnement du script par étapes-->

## Remerciements

Merci à mes amis qui me font avancer sur mes projets en me donnant des idées et en me motivant !
Kit!
neutaaaaan
