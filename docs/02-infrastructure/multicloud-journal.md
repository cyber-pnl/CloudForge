# Journal — Replication multi-cloud (AWS + Azure / Floci-AZ)

> **Objectif du journal.** Récapitule, en langage simple, les difficultés
> rencontrées pendant la réplication de la plateforme AWS vers Azure avec
> Floci-AZ. Il explique *ce que l'on a essayé*, *pourquoi cela n'a pas abouti*
> et *ce que l'on a finalement décidé*. Il sert de mémo pour les tentatives
> futures, sans se perdre dans les détails techniques.

## Contexte en une phrase

CloudForge émule AWS localement avec **Floci** et Azure localement avec
**Floci-AZ**. Le but était de répliquer l'infrastructure AWS en Azure et de
répartir le trafic **50/50** entre les deux clouds devant un gateway unifié
(port `4600`).

## Ce qui a fonctionné

- Les modules OpenTofu Azure sont écrits et **valident** :
  `azurerm` (`fmt-check`, `validate`, `plan`) réussissent contre Floci-AZ.
  Le `plan` construit proprement les **25 ressources** de l'environnement
  `dev-az`.
- Les services Azure suivants sont bien **émulés** par Floci-AZ et
  provisionnables côté gestion :
  - Cosmos DB, Blob/Queue Storage, Key Vault, Event Grid, API Management,
    Azure Monitor (Log Analytics), et une identité managée (Entra ID).

## Les difficultés rencontrées (et pourquoi on a changé d'avis)

### 1. Le problème : `tofu apply` ne fonctionne pas sur l'environnement Azure

Le `plan` passe, mais le **`apply` échoue**. Deux causes distinctes ont été
identifiées :

**a) Le routage « data-plane ».** Le provider `azurerm` construit les adresses
de ses services (stockage, key vault) à partir d'une découverte locale. Il
cherche alors des noms du type `cloudforgesa.blob.core.windows.net`, qui
renvoient vers le vrai Azure et **pas** vers l'émulateur. Sans mise en place
spécifique, l'`apply` se termine en erreur DNS.

- *Solution classique de Floci-AZ* : modifier `/etc/hosts` et installer un
  `socat` (port 80/443 → Floci-AZ). C'est exactement ce que fait la suite de
  tests de Floci-AZ elle-même.
- *Conséquence* : le correctif demande les droits **root** (modification de
  `/etc/hosts` + écoute sur les ports 80/443). Impossible à faire localement
  en simple utilisateur ; prévu pour l'environnement CI.

**b) Le vrai blocage : les Azure Functions ne peuvent pas être créées.**

En testant directement Floci-AZ, on a constaté que :

- `Microsoft.Web/sites` (la Function App) → **fonctionne** (création en `200`).
- `Microsoft.Web/serverfarms` (le plan App Service) → **404** : **non émulé**.

Or le provider `azurerm` exige un plan App Service avant de créer une Function
App. **Sans plan App Service, aucune Function App ne peut être déployée** via
le provider. Les 4 Function Apps du projet (users, projects, worker,
dispatcher) sont donc impossibles à provisionner.

> **Conclusion :** c'est un blocage *certain* (testé empiriquement), pas une
> simple hypothèse. La réplication complète du workload vers Azure ne peut pas
> aboutir actuellement.

### 2. Conséquence : un gateway 50/50 vers un workload Azure vide n'a pas de sens

Le gateway ne sait rien faire d'autre que renvoyer des requêtes. Répartir 50/50
le trafic vers Floci-AZ alors qu'**aucun workload applicatif** n'y est
déployable reviendrait à envoyer la moitié des requêtes vers une cible vide.
Ce n'est ni utile ni « operable ».

## La décision

1. **Gateway : tout le trafic va vers Floci (AWS).** Le load-balancing 50/50 et
   le backend Azure ont été retirés du gateway nginx. Il ne reste qu'un simple
   proxy vers le backend AWS (`floci:4566`).
2. La validation Azure est conservée en **validation IaC** (`fmt`, `validate`,
   `plan`) — cela fonctionne et évite que l'infrastructure Azure ne se
   dégrade. Elle ne fait **pas** d'`apply`/`destroy` ni de tests
   d'intégration, puisque le déploiement est bloqué.
3. Ce journal documente le pourquoi, pour que la décision reste explicable.

## Voies de sortie possibles (pour plus tard)

- Si Floci-AZ ajoute l'émulation de `Microsoft.Web/serverfarms` (App Service
  Plan), la réplication des Functions redevient possible : il faudra alors
  rétablir le routage data-plane, refaire l'`apply` complet et les tests
  d'intégration Azure, puis réactiver la répartition 50/50 dans le gateway.
- Sinon, remplacer Azure Functions par un autre service Azure réellement émulé
  (ex. Azure Container Apps / App Configuration) demanderait une
  re-conception de la couche exécution côté Azure.