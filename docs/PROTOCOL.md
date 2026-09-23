# Protocole et limites de vérification

Révision implémentée : [MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28), sur stdio (une ligne JSON-RPC par message). Le serveur ne dépend pas du SDK Swift MCP 0.12.1 du dépôt de référence.

| Exigence | Implémentation | Vérification locale |
| --- | --- | --- |
| `server/discover` | Versions, outils, identité dans `_meta`, cache public 5 min | XCTest et processus stdio |
| `_meta` par requête | Version + capacités client obligatoires ; `-32602` si absentes, `-32022` si version inconnue | XCTest |
| `tools/list` | Deux outils statiques, ordre stable, cache public 5 min, curseur inconnu refusé | XCTest et stdio |
| `tools/call` | Résultat complet, contenu texte et structuré ; paramètres inattendus et noms inconnus refusés | XCTest et stdio |
| Abonnements | `subscriptions/listen` accuse réception avec filtre vide, car le catalogue est fixe ; aucune notification `tools/list_changed` annoncée | XCTest |
| Arrêt | Lecture stdio jusqu'à EOF ; annulation d'abonnement reconnue | Test de processus |

La mise en cache est **un conseil au client** (`ttlMs`, `cacheScope`), pas un cache interne au serveur. Comme les outils sont fixes, `listChanged` n'est pas annoncé et aucun événement d'invalidation n'est émis. La découverte du serveur, la liste des outils et leur chargement dans le contexte d'un assistant sont trois étapes distinctes ; cette dernière dépend du client, pas du serveur.

Chaque diagnostic structuré renvoie `status` et `outcome` (`confirmed`, `uncertain` ou `refused`). Ce verdict décrit seulement l'observation faite par ce processus sur le Mac courant ; le champ `verification: unqualified_without_logic_pilots` rappelle que la compatibilité Logic n'a pas été établie par les pilotes.

La suite locale n'est pas une suite officielle de conformité. Elle vérifie les points essentiels des pages [Discovery](https://modelcontextprotocol.io/specification/2026-07-28/server/discover), [Tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools), [métadonnées](https://modelcontextprotocol.io/specification/2026-07-28/basic/index#meta), [Caching](https://modelcontextprotocol.io/specification/2026-07-28/server/utilities/caching) et [Subscriptions](https://modelcontextprotocol.io/specification/2026-07-28/basic/patterns/subscriptions).

Le [MCP Inspector CLI](https://modelcontextprotocol.io/docs/2026-07-28/tools/inspector/cli) version 2.7.0 est aussi exécuté en CI par `scripts/inspector_check.py` avec `protocolEra: modern` : connexion/discovery, `tools/list` et `tools/call` doivent réussir. Son mode par défaut est `legacy` et envoie `initialize` 2025-11-25, que ce serveur refuse correctement. Ces essais ne qualifient pas Logic Pro ni tous les aspects de la spécification.
