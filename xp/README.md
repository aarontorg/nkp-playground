# NKP and Crossplane

NKP comes out of the box with supported open source apps that are delivered on installation. However, all of them are not needed nor required. So customers have to decide which ones they want the cluster users to enable. The idea here is to have a cluster profile that can deliver the cluster and all of their apps with a single kubernetes API.

## What does it do?

- Create a single new kubernetes api (via crossplane) to create nkp mananaged clusters
- Create two compositions of the api to create different configurations of clusters
- Enables creating workload clusters with pre-configured apps

## Pre-Req/Setup

- Install NKP
- Have about X amount of IP address available for use on the 3 clusters that will be created
- Clone this git repo: 
    `git clone https://github.com/aarontorg/nkp-playground.git` **Request permission if needed**

## Management Cluster

All kubectl commands are executed on the management cluster.

### Install and Configure Crossplane

Do the following to install and configure open source crossplane and the kubernetes provider.

#### [Install](https://docs.crossplane.io/v2.2/get-started/install/)
- `helm repo add crossplane-stable https://charts.crossplane.io/stable`
- `helm repo update`
- `helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane`

Verify all pods in crossplane-system namespace are running

- `kubectl get pods -n crossplane-system`

#### Install Kubernetes and Helm Crossplane Providers

Ensure you are in the home directory of the nkp-playground git repo

- `kubectl apply -f ./xp/config/providers.yaml`
- `kubectl apply -f ./xp/config/provider-cfgs.yaml`

** Helm is installed, but not used yet.

##### Install the patch and transform crossplane function

- `kubectl apply -f ./xp/config/function.yaml`

##### Give xp-k8s service accounts cluster-admin permissions (hack)

- `export K8sSA=$(kubectl get sa -n crossplane-system | grep kubernetes | awk '{print $1}')`
- `kubectl create clusterrolebinding xp-k8s-admin --clusterrole=cluster-admin --serviceaccount=crossplane-system:${K8sSA}`

### XP-APIS

To create two workspaces and install the custom crossplane apis (XRDs & compositions) we'll utilize NKPs project functionality on the Managment Cluster Workspace. All steps below are done in the NKP UI and or kubectl on the management cluster.

- In the NKP UI, go to the management cluster workspace
- Create a new project named **xp-apis** (Use the same name for ID/Namespace)
- Add project to only the Kommander Host
- Give admin permission to xp-apis service account (hack). 
    `kubectl create clusterrolebinding xp-apis-admin --clusterrole=cluster-admin --serviceaccount=xp-apis:xp-apis`
- Go to the project in NKP UI
- If needed, create a secret for the nkp-playground git ops repo with username and password keys
- Create a new GitOps source in the Project
    **Name:** apis
    **Repository URL:** https://github.com/aarontorg/nkp-playground.git
    **Branch:** main
    **Path:** ./xp/apis
    **Primary Git Secret:** *Select one created for access*
- To verify install of apis
    `kubectl get workspaces -A` Should see devtest and production workspaces
    `kubectl get xrd` Should see clusterprofiles.nkp.io 
    `kubectl get compositions` Should see devtest & production

### Creating Clusters

We can now create clusters with ClusterProfile api and two compositions we created. To do this, we'll utilize another gitops repo within the xp-apis project on the management cluster. As before, we will utilize the NKP UI and kubectl on the management cluster.

- Go to the management cluster workspace and go in to the xp-apis project
- Check the folder xp/0-deploy before proceeding. Anything in this folder will be deployed. **If you do not want it to be deployed**, move it to the 0-stagging folder.
- For any cluster you are going to deploy, modify the example to meet your setup. Check each file in either 0-deploy or 0-stagging and search of MODIFY_THIS
- Create a new GitOps source
    **Name:** workload-clusters
    **Repository URL:** https://github.com/aarontorg/nkp-playground.git
    **Branch:** main
    **Path:** ./xp/0-deploy
    **Primary Git Secret:** *Select one created for access*
- After a few minutes a new cluster should be created

#### Details on Setup

Within the repo there are two folders 0-deploy and 0-stagging. As mentioned, anything in the 0-deploy folder will be deployed. There are three examples included. The devtest clusters utilize the devtest composition and the production example uses production. They are essentially the same except for the amount of nodes and the applications installed. Devtest has less apps and fewer workers.

The idea is that we can create profiles for the types of clusters that we want. We can hard code any value and/or expose it to the user for customizations. One idea is to be able to update/upgrade things much easier.
