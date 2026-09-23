# Pilote sur deux Mac Logic Pro

Deux volontaires : un Mac avec Logic **11.1.x**, un autre avec Logic **11.2.x**. Prévoir 15 à 20 minutes par personne. Cette procédure qualifie seulement les configurations exactes réellement essayées. Les tests de code et les fixtures ne comptent pas comme preuve Logic.

1. Noter la version complète dans **Logic Pro > À propos de Logic Pro**, la version macOS, la langue de l'interface Logic, Intel ou Apple Silicon, l'assistant MCP utilisé et la version `0.1.0-preview` du serveur. Ne pas inclure de nom de projet privé, fichier audio ou identité de compte.
2. Ouvrir Logic, puis lancer l'outil **État de Logic Pro**. Vérifier que la version et le profil automatique concordent avec la fenêtre « À propos ». Vérifier l'état Accessibilité ; si l'autorisation est refusée, le compte de fenêtres doit rester inconnu. Si elle est accordée, comparer le compte à l'écran, sans transmettre les titres de fenêtre.
3. Dans le client MCP, vérifier `server/discover`, `tools/list` et la présence de **État de Logic Pro** et **Diagnostic de connexion**. Si les outils ne sont pas visibles dans la conversation, reconnecter ou actualiser le client et retester. Une découverte du serveur seule ne prouve pas le chargement des outils par le client.
4. Appeler **Diagnostic de connexion**. Vérifier qu'il ne contient ni nom de projet ni chemin personnel. Fermer Logic puis refaire **État de Logic Pro** : `logic_not_running` doit apparaître. Rouvrir Logic si nécessaire.
5. Noter pour chaque étape : P1 ou P2, versions exactes, résultat attendu, résultat observé, PASS/FAIL/SKIP et éventuelle erreur. Un échec ne doit pas être réétiqueté en succès grâce à une fixture. Éviter les captures ; si indispensable, masquer les noms privés avant partage et demander l'accord du pilote.
6. Retirer l'entrée du serveur du client, relancer le client, vérifier que les deux outils ont disparu, puis retirer l'application et son autorisation Accessibilité comme décrit dans le README.

Les commandes de lecture, transport, pistes, MIDI et mixage sont **SKIP** dans cette préversion : elles ne sont pas exposées. Avant de les ajouter, préparer un projet jetable vide, vérifier visuellement chaque effet dans Logic, relire son état après action et refuser toute ambiguïté. Ne jamais tester l'enregistrement sur un projet de travail. Une fonction ne pourra être annoncée comme qualifiée qu'après des PASS distincts sur 11.1 et 11.2, avec numéro de correctif et environnement conservés dans le journal.

## Fiche de résultat à copier pour chaque pilote

La personne pilote peut remplir cette fiche localement puis vérifier les informations avant de la partager. Aucun journal complet, chemin personnel ou fichier de projet n'est nécessaire.

| Champ | Réponse |
| --- | --- |
| Pilote | P1 (11.1) / P2 (11.2) |
| Logic Pro (numéro complet) | |
| macOS (numéro complet) | |
| Langue de Logic | |
| Mac | Intel / Apple Silicon |
| Assistant MCP et version | |
| Serveur et protocole affichés | |
| Installation et première ouverture | PASS / FAIL / SKIP + observation |
| Version et profil automatiques comparés à « À propos » | PASS / FAIL / SKIP + observation |
| Autorisation Accessibilité et compte de fenêtres | PASS / FAIL / SKIP + observation |
| `server/discover`, `tools/list`, outils visibles dans le client | PASS / FAIL / SKIP + observation |
| `logic_status`, `logic_diagnostic`, absence de données privées | PASS / FAIL / SKIP + observation |
| Logic fermé puis `logic_not_running` | PASS / FAIL / SKIP + observation |
| Désinstallation et disparition des outils | PASS / FAIL / SKIP + observation |
| Transport, pistes, MIDI, mixage | SKIP : outils non exposés dans cette préversion |
