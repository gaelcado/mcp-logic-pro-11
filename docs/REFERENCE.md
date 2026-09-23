# Suivi du projet de référence

Projet : https://github.com/MongLong0214/logic-pro-mcp  
Licence constatée le 23 septembre 2026 : MIT.  
Révision initialement examinée : `ffcf0bf8ac0f93a7615fdce6b57d0b2fd5370575`.

## Règles de veille et de reprise

Examiner régulièrement les nouvelles issues, pull requests et versions qui touchent Logic 11, les canaux MIDI/MCU, les sélecteurs d'accessibilité, le protocole MCP, la sûreté des mutations et l'installation. Pour chaque changement retenu, consigner : lien, version visée, comportement mesuré ou seulement supposé, impact sur 11.1/11.2, risque de régression et décision d'intégration. Une pull request fusionnée n'est pas une preuve de compatibilité Logic 11.

Avant de reprendre du code, vérifier la licence du fichier et ses dépendances, garder l'attribution requise, isoler le comportement utilisé et lui donner des tests pertinents. Les changements importants de la référence font l'objet d'une revue de qualité avant intégration : exactitude des preuves, refus sûr en cas d'ambiguïté, effet sur les deux versions de Logic et facilité de retour arrière.

Le suivi peut être automatisé, mais un rapport ne doit être envoyé que lorsqu'un changement est pertinent ou nécessite une action.

## Audit du 23 septembre 2026

La [révision `ffcf0bf`](https://github.com/MongLong0214/logic-pro-mcp/tree/ffcf0bf8ac0f93a7615fdce6b57d0b2fd5370575) est un serveur Swift/macOS dont le catalogue contient dix outils statiques : transport, tracks, mixer, plugins, MIDI, edit, navigate, project, system et audio. Il route les actions par AppleScript, accessibilité, CoreMIDI/MCU, touches système et Scripter. Son [Package.swift](https://github.com/MongLong0214/logic-pro-mcp/blob/ffcf0bf8ac0f93a7615fdce6b57d0b2fd5370575/Package.swift) demande le SDK MCP Swift à partir de 0.11.0 ; le graphe résolu de cette révision utilise 0.12.1. Ni ce numéro de SDK ni ses tests sur Logic 12 ne prouvent MCP 2026-07-28 ou Logic 11.

| Surface amont | Valeur possible | Risque pour Logic 11.1/11.2 | Décision |
| --- | --- | --- | --- |
| MIDI SMF et décodage MCU purs | Utiles pour notes et transport | Port matériel, assignation et retour d'état dépendent du poste | Export MIDI format 1 réimplémenté indépendamment, sans code amont ; MCU différé |
| Chemins AX, menus et localisation | Potentiellement utiles aux pistes et au mixage | Noms/arbres d'interface non mesurés sur 11.1/11.2 | Ne pas importer |
| Routeur avec confirmation après action | Principe de refus sûr | Un succès technique peut n'avoir aucun effet dans Logic | Réimplémenter seulement le principe après preuve live |
| Serveur Swift/SDK MCP amont | Exemple de structure | Cible 12.x et protocole 2026-07-28 non démontré | Serveur indépendant sans dépendance externe |

La racine du projet amont est sous licence MIT, copyright Kolton Jacobs. Cette implémentation n'en copie **aucun code**, uniquement des constats et principes généraux ; aucun avis tiers supplémentaire n'est requis pour le code actuel. Toute future reprise substantielle devra garder l'avis MIT du fichier et examiner ses dépendances. Les frameworks Apple employés ici ne sont pas des dépendances du projet amont.

## Registre de veille au 23 septembre 2026

Les liens ci-dessous sont des tickets et PR, pas des essais locaux sur Logic 11.1 ou 11.2. Leurs mesures éventuelles sont celles rapportées par leurs auteurs.

| Lien | Preuve et portée | Impact/risque 11.1–11.2 | Décision |
| --- | --- | --- | --- |
| [#908](https://github.com/MongLong0214/logic-pro-mcp/issues/908), [PR #916](https://github.com/MongLong0214/logic-pro-mcp/pull/916) | La question des menus Drummer et du marqueur AXRuler sur Logic 11 demande encore des mesures ; la PR indique que Logic 11 n'est pas pris en charge | Chemins AX 11 inconnus ; risque de faux succès | Ne pas reprendre les fallbacks et qualifier séparément |
| [#854](https://github.com/MongLong0214/logic-pro-mcp/issues/854) | AXPress rapporté comme réussi sans action sur 18 des 19 boutons mute avant réglage du focus | Même mode d'échec possible, non mesuré sur 11 | Exiger lecture indépendante après action |
| [#864](https://github.com/MongLong0214/logic-pro-mcp/issues/864) | Undo via CC MIDI pouvait être annoncé réussi sans assignation effective | Assignation MIDI de chaque musicien inconnue | Refuser les commandes MIDI sans retour vérifiable |
| [PR #964](https://github.com/MongLong0214/logic-pro-mcp/pull/964) | Proposition de v3.17.0, packaging et correctifs ; ouverte au relevé | Aucune qualification 11 ; risque de reprendre un binaire 12.x | Ne pas intégrer ; surveiller les garde-fous de version et undo |
| [#965–#971](https://github.com/MongLong0214/logic-pro-mcp/issues/965) | Sept propositions de conception, sans implémentation ni nouvelle mesure live ; groupes, couleur, auxiliaires et visibilité | Aucun effet 11 mesuré ; complexité élevée | Hors MVP ; retenir l'exigence de refus des cibles ambiguës |
| [#972](https://github.com/MongLong0214/logic-pro-mcp/issues/972) | Proposition de lecture seule des plugins et signalement d'une dépendance réseau transitive du SDK | AX plugins 11 inconnu ; surface de dépendance plus large | Ne pas importer ; garder le coeur sans SDK externe |
| [#973](https://github.com/MongLong0214/logic-pro-mcp/issues/973), [PR #974](https://github.com/MongLong0214/logic-pro-mcp/pull/974) | Correction proposée pour une variation AX de fader mesurée par l'auteur sur 12.3.1 ; PR ouverte | Exactitude volume/pan 11 inconnue ; risque de valeur annoncée erronée | Ne pas importer ; mesurer sur les deux pilotes avant outil de mixage |

La veille récurrente de cette tâche ne signale que les changements pertinents ou une action nécessaire. Elle ne transforme pas un ticket fusionné, un test fixture ou Logic 12 en qualification Logic 11.
