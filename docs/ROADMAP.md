# Feuille de route

## Objectif

Créer un serveur MCP portable pour macOS, destiné à des musiciens utilisant Logic Pro 11.1 ou 11.2. « MCP V2 » signifie ici viser la révision du protocole `2026-07-28` et offrir une découverte utile des outils ; le numéro de version d'un SDK ne suffit pas à établir cette compatibilité.

## Contraintes établies

- Aucun Logic Pro local : ne jamais annoncer une opération comme validée par un test réel tant que les deux utilisateurs pilotes ne l'ont pas exercée sur la version exacte.
- Le dépôt de référence cible Logic 12.3, fixe un minimum à 12.0.1 et a décidé de ne pas prendre en charge Logic 11 (issue #908). Ses chemins d'accessibilité ne sont donc pas une preuve de compatibilité 11.
- Le dépôt de référence utilise le SDK Swift MCP 0.12.1 et un catalogue fixe de dix outils au commit `ffcf0bf8ac0f93a7615fdce6b57d0b2fd5370575` (22 septembre 2026).
- La découverte des capacités du serveur (`server/discover`), la liste des outils (`tools/list`) et le chargement d'outils à la demande côté client sont trois mécanismes distincts.

## Phases

1. **Cartographie** : inventorier les commandes et les canaux du dépôt de référence, les classer par valeur pour un musicien, risque de modification et dépendance à l'interface de Logic. Examiner les issues et pull requests pertinentes, et tenir un registre des constats avec liens, date et degré de confiance.
2. **Architecture** : choisir le langage, le SDK ou l'adaptateur de protocole à partir d'un essai de conformité MCP `2026-07-28`, du packaging macOS et d'un lancement simple pour le musicien. Justifier toute reprise de code et conserver les avis de licence requis.
3. **Profils Logic** : détecter 11.1 et 11.2, mapper les différences observables, refuser les opérations non qualifiées. Ne proposer un sélecteur manuel que lorsque la détection ne suffit pas ; documenter son effet.
4. **MVP hors Logic** : implémenter découverte, liste et appel d'outils, diagnostic, réponses structurées, contrôles de paramètres et chemins de refus. Tester le protocole et les composants purs avec des fixtures explicites ; éviter de transformer une simulation en preuve de fonctionnement dans Logic.
5. **Pilote sur deux machines** : donner une procédure courte et réversible, relever Logic/macOS/langue, puis exécuter une matrice de lecture et de modification avec vérification indépendante. Corriger les différences 11.1/11.2 à partir de ces observations.
6. **Publication utilisable** : livrer un binaire ou paquet macOS prêt à lancer, une installation courte, un diagnostic compréhensible, une procédure de désinstallation et une matrice de compatibilité honnête.

## Critères avant d'annoncer la compatibilité

- La révision MCP annoncée est vérifiée par un client ou une suite de conformité compatible ; un ancien client garde un chemin de compatibilité si celui-ci est promis.
- Chaque opération publiée nomme ses préconditions et retourne confirmé, incertain ou refusé selon les preuves disponibles.
- Les opérations qui modifient une session sont exercées sur Logic 11.1 et 11.2 avec lecture de l'état après action. Les variantes de langue et de version non exercées restent indiquées comme telles.
- Le README d'installation est exécutable par une personne sans Xcode, Swift, Node ni terminal avancé.

## Sources de départ

- Référence : https://github.com/MongLong0214/logic-pro-mcp
- Décision sur Logic 11 : https://github.com/MongLong0214/logic-pro-mcp/issues/908
- Notes de version Apple Logic 11 : https://support.apple.com/en-il/126835
- Spécification MCP 2026-07-28 : https://modelcontextprotocol.io/specification/2026-07-28

## Avancement vérifié le 23 septembre 2026

- Phases 1 et 2 : audit des canaux et dix outils amont consigné dans `REFERENCE.md`. Choix d'un serveur Swift sans dépendance de paquet, avec paquet universel macOS arm64/x86_64. Aucun code amont copié.
- Phase 3 : sélection automatique pure pour 11.1 et 11.2, avec refus des autres versions et ambiguïtés ; tests unitaires. La détection réelle du paquet Logic reste à observer chez les pilotes.
- Phase 4 : `server/discover`, métadonnées par requête, `tools/list`, `tools/call`, cache et accusé d'abonnement statique implémentés. Compatibilité `initialize` 2025-11-25 ajoutée. Deux diagnostics en lecture seule. Tests XCTest et échange stdio passent ; MCP Inspector CLI 2.7.0 confirme connexion, liste et appel dans les deux modes en CI. Aucun Logic local.
- Phases 5 et 6 : procédure pilote écrite, paquet préversion construit localement, non notarisé. Il faut encore les deux Mac Logic, un client MCP 2026-07-28 réel, des commandes musicales qualifiées et une identité Developer ID pour une distribution sans friction Gatekeeper.
