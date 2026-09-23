# Suivi du projet de référence

Projet : https://github.com/MongLong0214/logic-pro-mcp  
Licence constatée le 23 septembre 2026 : MIT.  
Révision initialement examinée : `ffcf0bf8ac0f93a7615fdce6b57d0b2fd5370575`.

## Règles de veille et de reprise

Examiner régulièrement les nouvelles issues, pull requests et versions qui touchent Logic 11, les canaux MIDI/MCU, les sélecteurs d'accessibilité, le protocole MCP, la sûreté des mutations et l'installation. Pour chaque changement retenu, consigner : lien, version visée, comportement mesuré ou seulement supposé, impact sur 11.1/11.2, risque de régression et décision d'intégration. Une pull request fusionnée n'est pas une preuve de compatibilité Logic 11.

Avant de reprendre du code, vérifier la licence du fichier et ses dépendances, garder l'attribution requise, isoler le comportement utilisé et lui donner des tests pertinents. Les changements importants de la référence font l'objet d'une revue de qualité avant intégration : exactitude des preuves, refus sûr en cas d'ambiguïté, effet sur les deux versions de Logic et facilité de retour arrière.

Le suivi peut être automatisé, mais un rapport ne doit être envoyé que lorsqu'un changement est pertinent ou nécessite une action.
