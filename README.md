# MCP Logic Pro 11

Une préversion pour connecter **Logic Pro 11.1 ou 11.2 sur Mac** à un assistant compatible avec **MCP 2026-07-28**. Elle donne aujourd'hui l'état de Logic et un diagnostic. Elle ne lance pas la lecture et ne modifie pas de projet musical.

## Ce qui marche aujourd'hui

| Fonction | État |
| --- | --- |
| Détecter Logic ouvert et sa version | Implémenté, à vérifier sur Logic réel |
| Choisir automatiquement le profil 11.1 ou 11.2 | Implémenté, à vérifier sur les deux versions |
| Vérifier l'autorisation Accessibilité et compter les fenêtres | Implémenté, à vérifier sur Logic réel |
| Découverte et appels MCP 2026-07-28 | Testés sur le protocole, sans Logic local |
| Lecture, transport, pistes, MIDI, mixage | Pas encore proposés : comportement à mesurer sur les deux machines pilotes |

Les tests automatiques vérifient le serveur et ses réponses MCP. **Ils ne prouvent pas que les commandes fonctionnent dans Logic.** Deux musiciens, l'un sur 11.1 et l'autre sur 11.2, doivent tester la préversion avant toute annonce de compatibilité. Voir [la procédure pilote](docs/PILOT.md).

## Installer la préversion

1. Téléchargez le fichier `logic-pro-11-mcp-0.1.0-preview-macos-universal.zip` depuis l'artefact de la [dernière compilation GitHub](https://github.com/gaelcado/mcp-logic-pro-11/actions/workflows/build.yml), puis décompressez-le.
2. Glissez `Logic Pro 11 MCP.app` dans le dossier **Applications** du Mac. Aucun Xcode, Swift, Node ou Homebrew n'est requis pour lancer le paquet.
3. Dans votre assistant **compatible MCP 2026-07-28 et avec les serveurs locaux stdio**, ajoutez un serveur avec la commande ci-dessous et laissez les arguments vides.

   ```text
   /Applications/Logic Pro 11 MCP.app/Contents/MacOS/logic-pro-11-mcp
   ```

4. Relancez l'assistant et demandez « Donne-moi l'état de Logic Pro ». Si votre assistant ne montre pas les deux outils, reconnectez le serveur ou actualisez ses outils. Un serveur découvert par MCP ne signifie pas que l'assistant a chargé ses outils dans la conversation.

Le paquet de préversion est **signé localement, sans notarisation Apple** : macOS peut demander d'autoriser son ouverture dans Réglages Système > Confidentialité et sécurité. La distribution publique simple nécessitera une signature Developer ID et une notarisation ; elles ne sont pas disponibles dans cette tâche. N'accordez l'accès Accessibilité que si le diagnostic signale qu'il manque et si vous souhaitez essayer la lecture des fenêtres. Le serveur ne demande pas d'accès complet au disque ni de permission Apple Events.

L'assistant doit prendre en charge la révision **2026-07-28**. Un client qui ne connaît que le vieux démarrage `initialize` ne se connectera pas à cette préversion ; consultez les capacités de votre assistant. Les formats de configuration varient selon le client.

## Diagnostic et retrait

L'outil **Diagnostic de connexion** donne la version de Logic, le profil choisi, les versions du serveur, de MCP et de macOS, l'architecture du Mac, l'état de l'autorisation Accessibilité et un compte de fenêtres. Il ne donne ni nom de projet ni nom de piste. Si Logic est fermé, si sa version est illisible ou si plusieurs processus correspondent, le serveur refuse de deviner un profil. Aucun réglage manuel 11.1/11.2 n'est nécessaire tant que la lecture fiable de la version n'a pas été démentie par les pilotes.

Pour désinstaller : supprimez **uniquement** l'entrée « Logic Pro 11 MCP » dans la configuration de votre assistant, relancez celui-ci, puis mettez `Logic Pro 11 MCP.app` à la Corbeille. Si vous aviez accordé Accessibilité, retirez cette autorisation dans Réglages Système > Confidentialité et sécurité > Accessibilité. Cette procédure ne touche ni vos projets ni les préférences Logic.

## Développement

Les contributeurs peuvent lancer `swift test`, puis `sh scripts/package.sh` sur un Mac avec Xcode Command Line Tools. Le script construit un paquet universel dans `dist/`. Le serveur est écrit en Swift, sans dépendance de paquet externe. Il expose deux outils en lecture seule, un catalogue déterministe, des indices de cache publics et une réponse aux abonnements qui reconnaît qu'aucun événement n'est pris en charge. Voir [le statut du protocole](docs/PROTOCOL.md), [les différences 11.1/11.2](docs/LOGIC_VERSIONS.md) et [l'audit amont](docs/REFERENCE.md).

Projet communautaire indépendant ; non affilié à Apple. Logic Pro est une marque d'Apple Inc.
