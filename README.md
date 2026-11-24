# AutoUpdateAppsByGPO
Mise à jour automatique d'apps par GPO
AutoUpdateAppsByGPO
Moteur PowerShell générique permettant le déploiement et la mise à jour automatique d'applications Windows via GPO Startup Script.

Fonctionnalités
Déploiement MSI et EXE
Comparaison de versions
Mise à jour uniquement si nécessaire
Protection contre les downgrades
Journalisation locale
Journalisation dans l'Observateur d'événements Windows
Centralisation des logs
Configuration post-installation
Redémarrage de services
Applications actuellement gérées
7-Zip
Mozilla Firefox
VLC Media Player
TeamViewer Host
TightVNC
OCS Inventory NG Agent
Fichiers
Fichier	Description
Applications.psd1	Configuration des applications
Deploy-Applications.ps1	Moteur de déploiement
Deploy-Applications.bat	Lanceur GPO
Déploiement GPO
Configuration ordinateur

Windows Settings
 └ Startup Scripts
