# MCP Logic Pro 11

Une préversion pour connecter **Logic Pro 11.1 ou 11.2 sur Mac** à un assistant MCP. Elle prend en charge la révision **2026-07-28** et le démarrage plus ancien **2025-11-25**. Elle donne l'état de Logic, un diagnostic et crée des motifs MIDI à importer. Elle ne lance pas la lecture et ne modifie pas directement de projet musical.

## Ce qui marche aujourd'hui

| Fonction | État |
| --- | --- |
| Détecter Logic ouvert et sa version | Implémenté, à vérifier sur Logic réel |
| Choisir automatiquement le profil 11.1 ou 11.2 | Implémenté, à vérifier sur les deux versions |
| Vérifier l'autorisation Accessibilité et compter les fenêtres | Implémenté, à vérifier sur Logic réel |
| Découverte et appels MCP 2026-07-28 et 2025-11-25 | Testés avec MCP Inspector, sans Logic local |
| Créer et vérifier un fichier MIDI à pistes séparées | Testé hors Logic ; import dans Logic à vérifier sur les deux machines pilotes |
| Lecture dans Logic, transport, pistes, mixage | Pas encore proposés : comportement à mesurer sur les deux machines pilotes |

Les tests automatiques vérifient le serveur et ses réponses MCP. **Ils ne prouvent pas que les commandes fonctionnent dans Logic.** Deux musiciens, l'un sur 11.1 et l'autre sur 11.2, doivent tester la préversion avant toute annonce de compatibilité. Voir [la procédure pilote](docs/PILOT.md).

## Installer la préversion

1. Téléchargez le fichier `logic-pro-11-mcp-0.2.0-preview-macos-universal.zip` depuis l'artefact de la [dernière compilation GitHub](https://github.com/gaelcado/mcp-logic-pro-11/actions/workflows/build.yml), puis décompressez-le. Le fichier `Lisez-moi.txt` rappelle les étapes.
2. Glissez `Logic Pro 11 MCP.app` dans le dossier **Applications** du Mac. Aucun Xcode, Swift, Node ou Homebrew n'est requis pour lancer le paquet.
3. Dans votre assistant **compatible avec les serveurs MCP locaux stdio**, ajoutez un serveur avec la commande ci-dessous et laissez les arguments vides.

   ```text
   /Applications/Logic Pro 11 MCP.app/Contents/MacOS/logic-pro-11-mcp
   ```

4. Relancez l'assistant et demandez « Donne-moi l'état de Logic Pro ». Si votre assistant ne montre pas les quatre outils, reconnectez le serveur ou actualisez ses outils. Un serveur découvert par MCP ne signifie pas que l'assistant a chargé ses outils dans la conversation.

Pour créer de la musique, demandez par exemple « Crée un motif MIDI à 120 BPM, avec une piste Piano jouant do4 au temps 0 pendant un temps et mi4 au temps 1 pendant un temps ». L'outil **Créer un motif MIDI** écrit un nouveau fichier `.mid` dans `Musique/Logic Pro 11 MCP Exports` et indique son chemin. Importez ensuite ce fichier dans Logic. **Vérifier un export MIDI** relit les pistes, le nombre de notes et l'empreinte du fichier. Le son dépendra des instruments choisis dans Logic ; ce serveur n'attribue pas d'instrument. Le format de fichier est testé automatiquement, mais l'import dans Logic 11.1/11.2 sera vérifié par les deux pilotes.

Le paquet de préversion est **signé localement, sans notarisation Apple** : macOS peut demander d'autoriser son ouverture dans Réglages Système > Confidentialité et sécurité. La distribution publique simple nécessitera une signature Developer ID et une notarisation ; elles ne sont pas disponibles dans cette tâche. N'accordez l'accès Accessibilité que si le diagnostic signale qu'il manque et si vous souhaitez essayer la lecture des fenêtres. Le serveur ne demande pas d'accès complet au disque ni de permission Apple Events.

Le serveur choisit automatiquement l'échange **2026-07-28** ou **2025-11-25** selon la demande de l'assistant. Les formats de configuration varient selon le client ; aucun réglage de version n'est demandé au musicien.

## Diagnostic et retrait

L'outil **Diagnostic de connexion** donne la version de Logic, le profil choisi, les versions du serveur, de MCP et de macOS, l'architecture du Mac, l'état de l'autorisation Accessibilité et un compte de fenêtres. Il ne donne ni nom de projet ni nom de piste. Si Logic est fermé, si sa version est illisible ou si plusieurs processus correspondent, le serveur refuse de deviner un profil. Aucun réglage manuel 11.1/11.2 n'est nécessaire tant que la lecture fiable de la version n'a pas été démentie par les pilotes.

Pour désinstaller : supprimez **uniquement** l'entrée « Logic Pro 11 MCP » dans la configuration de votre assistant, relancez celui-ci, puis mettez `Logic Pro 11 MCP.app` à la Corbeille. Si vous aviez accordé Accessibilité, retirez cette autorisation dans Réglages Système > Confidentialité et sécurité > Accessibilité. Cette procédure ne touche ni vos projets ni les préférences Logic. Les fichiers `.mid` créés dans `Musique/Logic Pro 11 MCP Exports` restent sur le Mac : supprimez ce dossier séparément si vous n'en avez plus besoin.

## Développement

Les contributeurs peuvent lancer `swift test`, puis `sh scripts/package.sh` sur un Mac avec Xcode Command Line Tools. Le script construit un paquet universel dans `dist/`. Le serveur est écrit en Swift, sans dépendance de paquet externe. Il expose quatre outils, un catalogue déterministe, des indices de cache publics et une réponse aux abonnements qui reconnaît qu'aucun événement n'est pris en charge. Voir [le statut du protocole](docs/PROTOCOL.md), [les différences 11.1/11.2](docs/LOGIC_VERSIONS.md) et [l'audit amont](docs/REFERENCE.md).

Projet communautaire indépendant ; non affilié à Apple. Logic Pro est une marque d'Apple Inc.
