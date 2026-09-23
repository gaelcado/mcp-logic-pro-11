# Profils Logic 11.1 et 11.2

Le serveur recherche le processus dont l'identifiant de paquet est `com.apple.logic10`, lit `CFBundleShortVersionString` dans son paquet et sélectionne 11.1 ou 11.2 selon les deux premiers nombres. Les suffixes exacts (11.1.x, 11.2.x) restent dans le diagnostic. Il refuse une autre version, une version illisible et plusieurs processus correspondants. L'identifiant de paquet doit être vérifié par les pilotes sur des installations réelles ; aucune machine Logic n'est disponible ici. Aucun sélecteur manuel n'est fourni car aucune ambiguïté de détection n'a encore été observée.

Selon les [notes Apple](https://support.apple.com/en-il/126835), 11.2 ajoute notamment Flashback Capture et la recherche/sélection des pistes, et modifie plusieurs comportements MIDI, d'automation et d'accessibilité. 11.1 comporte aussi des changements MIDI, d'automation et VoiceOver. Les corrections 11.2.1 et 11.2.2 touchent notamment des contrôleurs et l'automation. Ces notes prouvent des différences produit, **pas** la stabilité des chemins d'accessibilité ou des commandes MCP. Les deux profils ont donc le même catalogue de deux diagnostics tant qu'aucune opération musicale n'est qualifiée sur les deux versions.

| Profil | Version détectée | Actions musicales qualifiées |
| --- | --- | --- |
| 11.1 | `11.1` ou `11.1.x` | Aucune |
| 11.2 | `11.2` ou `11.2.x` | Aucune |

La comparaison de la version automatique avec « Logic Pro > À propos de Logic Pro » fait partie du pilote. Si elle diverge, arrêter les tests de commande et ouvrir un incident avec la version complète.
