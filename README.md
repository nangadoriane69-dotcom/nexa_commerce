
# NexaCommerce – Projet 1 : Fondations Data Engineering

## Description du projet

Ce projet constitue la première étape du programme **Data & AI Engineer** de la DHI Academy. Il vise à poser les bases techniques et analytiques pour la startup camerounaise fictive **NexaCommerce**.

**Objectifs :**
- Mettre en place un environnement Python professionnel (Poetry, Git, pre-commit)
- Auditer et nettoyer des données opérationnelles (MySQL, Pandas)
- Réaliser une analyse exploratoire complète (statistiques, visualisations)
- Produire un rapport actionnable pour le comité de direction

**Livrables :**
- Module Python `data_loader.py`
- Scripts de nettoyage et d'analyse
- Requêtes SQL d'audit (CTEs, window functions)
- Visualisations (Matplotlib/Seaborn)
- Rapport final (PPT/Word)

---

## Prérequis

- **Python** 3.11 ou supérieur
- **Poetry** (gestionnaire de dépendances)
- **MySQL** (pour la partie SQL)
- **Git** (versionnement)

---

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/ton-compte/nexacommerce-project.git
cd nexacommerce-project
```

2. Installer Poetry (si ce n'est pas déjà fait)

```bash
pip install poetry
```

3. Installer les dépendances

```bash
poetry install
```

4. Activer l'environnement virtuel

```bash
poetry shell
```

5. Installer les hooks pre-commit

```bash
pre-commit install
```

---


Utilisation

Charger et inspecter les données

```python
from src.data_loader import load_dataset, inspect_dataset

df_orders = load_dataset("data/raw/orders.csv")
inspect_dataset(df_orders, "Commandes")
```

Lancer le pipeline de nettoyage

```bash
python src/data_cleaner.py
```

Exécuter les tests unitaires

```bash
pytest tests/ -v --cov=src
```

Exécuter les requêtes SQL d'audit

```bash
mysql -u root -p nexa_commerce < sql/audit_queries.sql
```

---

Principales fonctionnalités

Module Fonction
data_loader.py Chargement CSV, inspection automatique, détection doublons
data_cleaner.py Nettoyage dates, normalisation villes, correction montants
sql_queries.py Exécution requêtes CTEs et window functions
stats_analyzer.py Tests t de Student, IQR outliers, corrélations

---

Résultats clés

· 3% de commandes orphelines identifiées
· 10% de clients en doublon (téléphone)
· 7 livreurs en dégradation sévère (+15 à +36 min)
· Yaoundé : taux de retard de 32% (vs 19% à Bafoussam)

Rapport complet disponible dans /reports/executive_summary.md

---

Tests et couverture

```bash
pytest tests/ --cov=src --cov-report=term-missing
```

Objectif : couverture minimale de 60% (atteinte)

---

Bonnes pratiques appliquées

· ✅ Poésy pour la gestion des dépendances
· ✅ pre-commit (Black + Flake8)
· ✅ Docstrings pour chaque fonction
· ✅ Aucune valeur en dur (hardcoding)
· ✅ Visualisations : titres, axes, sources
· ✅ Au moins 10 commits Git significatifs

---

Auteure

Hélène NANGA – Junior Data & AI Engineer
Encadrée par Kevin MBARGA (Directeur Technique – NexaCommerce Cameroun)

Formation DHI Academy – Mars 2026

---

Licence

Ce projet est réalisé dans le cadre d'une formation. Usage pédagogique uniquement.

---

Remerciements

· DHI Academy pour la formation
· NexaCommerce Cameroun pour le cas d'usage réel
· Communauté open source (Pandas, Poetry, Pytest)

```

---

## Instructions complémentaires si tu veux enrichir

| Élément | Ce que tu peux ajouter |
|---------|------------------------|
| Badges | `![Python](https://img.shields.io/badge/Python-3.10-blue)` |
| Exemple d'exécution | Capture d'écran du terminal ou notebook |
| Problèmes connus | Section "Known issues" |
| Contribution | Comment contribuer (si projet collaboratif) |

Tu veux que j'ajoute des **badges de statut** ou une section **"Déploiement"** ?