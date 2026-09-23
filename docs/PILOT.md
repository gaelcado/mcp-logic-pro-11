# Pilote sur deux Mac Logic Pro

Deux volontaires : un Mac avec Logic **11.1.x**, un autre avec Logic **11.2.x**. Prévoir 20 à 30 minutes par personne. Cette procédure qualifie seulement les configurations exactes réellement essayées. Les tests de code et les fixtures ne comptent pas comme preuve Logic.

1. Noter la version complète dans **Logic Pro > À propos de Logic Pro**, la version macOS, la langue de l'interface Logic, Intel ou Apple Silicon, l'assistant MCP utilisé et la version `0.2.0-preview` du serveur. Ne pas inclure de nom de projet privé, fichier audio ou identité de compte.
2. Ouvrir Logic, puis lancer l'outil **État de Logic Pro**. Vérifier que la version et le profil automatique concordent avec la fenêtre « À propos ». Vérifier l'état Accessibilité ; si l'autorisation est refusée, le compte de fenêtres doit rester inconnu. Si elle est accordée, comparer le compte à l'écran, sans transmettre les titres de fenêtre.
3. Dans le client MCP, vérifier la connexion (`server/discover` en 2026-07-28 ou `initialize` en 2025-11-25), puis `tools/list` et la présence des quatre outils : **État de Logic Pro**, **Diagnostic de connexion**, **Créer un motif MIDI**, **Vérifier un export MIDI**. Si les outils ne sont pas visibles dans la conversation, reconnecter ou actualiser le client et retester. Une connexion réussie ne prouve pas le chargement des outils par le client.
4. Appeler **Diagnostic de connexion**. Vérifier qu'il ne contient ni nom de projet ni chemin personnel. Fermer Logic puis refaire **État de Logic Pro** : `logic_not_running` doit apparaître. Rouvrir Logic si nécessaire.
5. Dans un projet Logic **jetable**, demander : « Crée un motif MIDI nommé Test pilote à 120 BPM, en 4/4, avec une piste Piano canal 1 contenant do4 (MIDI 60) du temps 0 au temps 1 et mi4 (MIDI 64) du temps 1 au temps 2, et une piste Basse canal 2 contenant do2 (MIDI 36) du temps 0 au temps 2. » Vérifier que le serveur annonce un fichier `.mid`, trois pistes dans le fichier (dont une piste de tempo), trois notes au total, `fileConfirmed: true` et `logicImportQualification: unverified`. Appeler **Vérifier un export MIDI** avec le seul nom du fichier et comparer le SHA-256 ; il doit être identique. Ne partager que le nom de fichier et l'empreinte, sans chemin personnel.
6. Importer le fichier `.mid` dans le projet jetable avec la commande d'import MIDI de Logic, selon la [procédure Apple pour les Standard MIDI Files](https://support.apple.com/en-ae/guide/logicpro/lgcpdf6a3851/10.7/mac/11.0). Noter la méthode d'import choisie. Vérifier visuellement que Piano et Basse forment deux pistes ou régions distinctes, avec deux notes 60/64 aux positions 0/1 et une note 36 à la position 0, toutes aux durées demandées. Vérifier le tempo à 120 BPM et la mesure à 4/4 ; signaler si Logic demande de conserver le tempo du projet. Le choix des instruments et le rendu sonore ne font pas partie de ce test.
7. Noter pour chaque étape : P1 ou P2, versions exactes, résultat attendu, résultat observé, PASS/FAIL/SKIP et éventuelle erreur. Un échec ne doit pas être réétiqueté en succès grâce à une fixture. Éviter les captures ; si indispensable, masquer les noms privés avant partage et demander l'accord du pilote.
8. Retirer l'entrée du serveur du client, relancer le client, vérifier que les quatre outils ont disparu, puis retirer l'application et son autorisation Accessibilité comme décrit dans le README. Supprimer séparément le projet et le fichier MIDI jetables après le test.

Les commandes qui agissent **directement dans Logic** sur la lecture, le transport, les pistes ou le mixage sont **SKIP** dans cette préversion. L'export MIDI, lui, est à tester comme indiqué. Avant d'ajouter une action directe, utiliser un projet jetable, vérifier visuellement chaque effet dans Logic, relire son état après action et refuser toute ambiguïté. Ne jamais tester l'enregistrement sur un projet de travail. Une fonction ne pourra être annoncée comme qualifiée qu'après des PASS distincts sur 11.1 et 11.2, avec numéro de correctif et environnement conservés dans le journal.

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
| `server/discover` ou `initialize`, `tools/list`, outils visibles dans le client | PASS / FAIL / SKIP + observation |
| `logic_status`, `logic_diagnostic`, absence de données privées | PASS / FAIL / SKIP + observation |
| Logic fermé puis `logic_not_running` | PASS / FAIL / SKIP + observation |
| Fichier MIDI créé : nom, trois pistes, trois notes, tempo, mesure | PASS / FAIL / SKIP + observation |
| Relecture du MIDI : SHA-256 identique | PASS / FAIL / SKIP + observation |
| Import dans Logic : pistes, notes, positions, durées, tempo, mesure | PASS / FAIL / SKIP + méthode d'import et observation |
| Désinstallation et disparition des outils | PASS / FAIL / SKIP + observation |
| Actions directes sur transport, pistes, mixage | SKIP : outils non exposés dans cette préversion |
