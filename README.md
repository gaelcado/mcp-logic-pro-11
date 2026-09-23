# MCP Logic Pro 11

Un projet de serveur MCP pour piloter **Logic Pro 11.1 et 11.2 sur Mac** depuis un assistant compatible MCP.

## État du projet

Le serveur est en préparation. **Ne l'installez pas encore pour une session musicale importante.** Nous n'avons pas d'installation locale de Logic Pro 11 pour vérifier les commandes dans l'application. Deux utilisateurs testeront une première version avant qu'une compatibilité soit annoncée.

Le premier objectif est un contrôle fiable des fonctions courantes : lire l'état du projet, transporter la lecture, choisir et créer des pistes, puis manipuler MIDI et mixage. Une commande qui ne peut pas vérifier son effet doit le dire clairement.

## Installer

Les instructions d'installation destinées aux musiciens seront ajoutées avec la première version testable. Elles devront permettre de télécharger une application prête à l'emploi, de lui donner les autorisations macOS nécessaires et de la connecter à un assistant MCP sans installer d'outils de développement.

## Compatibilité visée

| Application | État |
| --- | --- |
| Logic Pro 11.1 | À étudier et tester |
| Logic Pro 11.2 | À étudier et tester |
| Logic Pro 12 | Hors objectif initial |

Le serveur doit détecter la version de Logic et choisir automatiquement les comportements validés pour elle. Si une différence ne peut pas être détectée de façon fiable, un réglage manuel documenté sera proposé.

## Projet de référence

Nous étudions [logic-pro-mcp](https://github.com/MongLong0214/logic-pro-mcp), un projet communautaire sous licence MIT qui cible d'abord Logic Pro 12. Les idées et le code réutilisés seront crédités et vérifiés pour Logic Pro 11 avant d'être intégrés. Voir [la feuille de route](docs/ROADMAP.md) et [les règles de suivi de la référence](docs/REFERENCE.md).

## Retours

Quand une version testable sera disponible, les deux premiers utilisateurs pourront signaler la version exacte de Logic et de macOS, la langue de Logic, l'opération demandée, ce qui s'est produit et le résultat du diagnostic. Aucun projet musical ne devrait être nécessaire pour décrire un problème.
