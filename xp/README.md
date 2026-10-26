# NKP and Crossplane

NKP is a platform to standardize kubernetes operations. Crossplane is a tool to allow you to build custom APIs to further standardization of infrastructure delivery. Together,
they become a very powerful combination to deliver the quintessential cloud native platform!

## What will following these steps do

- Create a single new kubernetes api and crossplane composition to create NKP managed workload clusters
- In addition to creating the clusters, the Crossplane API will also deploy a simple policy to the clusters to dissallow using the latest image tag

## Pre-Req/Setup

- Install NKP
- Clone this git repo: 
    `git clone https://github.com/aarontorg/nkp-playground.git` **Request permission if needed**

## Management Cluster

The following is done on the management cluster

### Install and Configure Crossplane

Do the following to install and configure open source crossplane and the kubernetes provider.

#### [Install](https://docs.crossplane.io/v2.2/get-started/install/)
- `helm repo add crossplane-stable https://charts.crossplane.io/stable`
- `helm repo update`
- `helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane`

Verify all pods in crossplane-system namespace are running

- `kubectl get pods -n crossplane-system`

#### Install Crossplane Kubernetes Provider

Ensure you are in the home directory of the nkp-playground git repo

- `kubectl apply -f ./xp/config/providers.yaml`
- `kubectl apply -f ./xp/config/provider-cfgs.yaml`

##### Install the patch and transform crossplane function

- `kubectl apply -f ./xp/config/function.yaml`

##### Give xp-k8s service accounts cluster-admin permissions (hack)

- `export K8sSA=$(kubectl get sa -n crossplane-system | grep kubernetes | awk '{print $1}')`
- `echo $K8sSA` [should be crossplane-contrib-provider-kubernetes-xxxxxxxxxx]
- `kubectl create clusterrolebinding xp-k8s-admin --clusterrole=cluster-admin --serviceaccount=crossplane-system:${K8sSA}`

### SETUP

#### Create the project

- In the NKP UI, go to the Management Cluster Workspace
- Create a new project named **xp-apis** (Use the same name for ID/Namespace)
- Add project to only the Kommander Host
- Give admin permission to xp-apis service account (hack)
    - `kubectl create clusterrolebinding xp-apis-admin --clusterrole=cluster-admin --serviceaccount=xp-apis:xp-apis`

#### Create a Workspace for your workload clusters

In NKP, Workspaces are utilized to configure clusters and enable application for every cluster created within the workspace

- In NKP UI, create a new workspace
    - **Name:** workloads
    - **ID/Namespace:** workloads
    - **Description:** workspace to create clusters
- Once workspace is created, verify the following Applications are enabled.
    - Foundational : Reloader, Traefik
    - Security: Gatekeeper, cert-manager
    - Monitoring: Headlamp
    - Anything else you want

#### apis Gitops Source

- In the NKP-UI, Go to the Management Cluster Workspace.
- Go to Projects and select the xp-apis project
- If needed, create a secret for the nkp-playground git ops repo with username and password keys
- Go to the Continuous Deployment (CD) tab
- Add a new GitOps source in the Project
    - **Name:** apis
    - **Repository URL:** https://github.com/aarontorg/nkp-playground.git
    - **Branch:** main
    - **Path:** ./xp/apis
    - **Primary Git Secret:** *Select one created for access*
- To verify install of workspaces (* add projects)
    `kubectl get xrd` Should see workloadclusters.nkp.io 
    `kubectl get compositions` Should see devtest & production

#### Creating Workload Clusters

We can now create clusters with newly create Crossplane created WorkloadCluster xrd/api and the workload composition. To do this, we'll utilize a gitops repo within the xp-apis project on the management cluster. As before, we will utilize the NKP UI and kubectl on the management cluster.

In the nkp-playground repo
 **Check the folder xp/0-deploy before proceeding. Anything in this folder will be deployed. **If you do not want it to be deployed**, move it to the 0-stagging folder.**
 **For any cluster you are going to deploy, modify the example to meet your setup. Check each file in either 0-deploy or 0-stagging and search for #MODIFY_THIS.

- In the NKP UI, go to the management cluster workspace and go in to the xp-apis project
- Create a new GitOps source
    - **Name:** workload-clusters
    - **Repository URL:** https://github.com/aarontorg/nkp-playground.git
    - **Branch:** main
    - **Path:** ./xp/0-deploy
    - **Primary Git Secret:** *Select one created for access*
- After 1-2 minutes a new cluster should start being created if you have a cluster in 0-deploy folder
    - `kubectl get clusters -A` [new cluster should be in list]
    - `kubectl get providers.kubernetes` [new provider config with the clusters name]
    - Showcase the gatekeeper security policy that has been created on the workload cluster ... 

#### Details on Setup

Within the repo there are two folders 0-deploy and 0-stagging. As mentioned, anything in the 0-deploy folder will be deployed. There are three examples included. The devtest clusters utilize the devtest composition and the production example uses production. They are essentially the same except for the amount of nodes and the applications installed. Devtest has less apps and fewer workers.

The idea is that we can create profiles for the types of clusters that we want. We can hard code any value and/or expose it to the user for customizations. One idea is to be able to update/upgrade things much easier.
