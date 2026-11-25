# NKP and Crossplane

NKP is a platform to standardize kubernetes operations. Crossplane is a tool to allow you to build custom APIs to further standardization of infrastructure delivery. Together, they become a very powerful combination to deliver the quintessential cloud native platform!

## What will following these steps do

- Create a single new kubernetes api and crossplane composition to create NKP managed workload clusters
- In addition to creating the clusters, the Crossplane API will also deploy a simple policy to the clusters to dissallow using the latest image tag

## Pre-Req/Setup

- Install NKP
- Have nkp cli available where script will run
- Clone this git repo: 
    `git clone https://github.com/aarontorg/nkp-playground.git` **Request permission if needed**
- Create a branch and switch to it `git checkout -b <branch-name>`
- If there are any files in xp/workload-clusters/deploy move them to xp/workload-clusters/stagging.
- Add, commit and push your changes to your branch

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

##### Give crossplane service accounts cluster-admin permissions (hack)

- `export K8sSA=$(kubectl get sa -n crossplane-system | grep kubernetes | awk '{print $1}')`
- `echo $K8sSA` [should be crossplane-contrib-provider-kubernetes-xxxxxxxxxx]
- `kubectl create clusterrolebinding xp-k8s-admin --clusterrole=cluster-admin --serviceaccount=crossplane-system:${K8sSA}`

### SETUP

#### Create a project in NKP

- In the NKP UI, go to the Management Cluster Workspace
- Create a new project named **nkp-playground** (Use the same name for ID/Namespace)
- Add project to only the Kommander Host
- Give admin permission to management service account (hack)
    - `kubectl create clusterrolebinding nkp-playground-admin --clusterrole=cluster-admin --serviceaccount=nkp-playground:nkp-playground`

#### Create workspaces via command line

The command below will run a script to create workspace-0, workspace-1, and workspace-2. You can create these in the UI if you prefer.

- `./xp/misc/create-workspaces.sh`

#### Create management Gitops Source

When the management gitops source is created it will do the following:
1. Create a GitOps source in the nkp-playground project called apis. This will load the crossplane api and compositions.
2. Create a GipOps source in the nkp-playground project called workload-clusters. This will be used to create workload clusters.

##### Steps

1. Modify xp/management/mgmt-config.yaml
    - Change the branch to your branch (two locations)
    - Check in your changes to git
2. NKP-UI, Go to the Management Cluster Workspace.
3. Go to Projects and select the nkp-playground project
4. Go to the secrets tab and Create a secret named **nkp-playgound** for the nkp-playground project repo with username and password keys
5. Go to the Continuous Deployment (CD) tab
6. Add a new GitOps source in the Project
    - **Name:** management
    - **Repository URL:** https://github.com/aarontorg/nkp-playground.git
    - **Branch:** [your branch]
    - **Path:** ./xp/management
    - **Primary Git Secret:** nkp-playground
7. To verify install of the Crossplane APIs
    - `kubectl get gitopsrepositories,xrd,compositions -n nkp-playground` 
        - GitOpsRepositories: management,apis, workload-clusters 
        - XRD: workloadclusters.nkp.io
        - Compositions: workload

#### Creating Workload Clusters

We can now create clusters with newly create Crossplane created WorkloadCluster xrd/api and the workload composition. To do this, we'll utilize gitops repos called workload-clusters within the nkp-playground project we created on the management cluster.

Do the following to create a workload cluster
1. Modify **xp/workload-clusters/stage/workload1-cluster.yaml**. Look for #MODIFY_THIS and make changes to fit your environment.
2. Move **xp/workload-clusters/stage/workload1-cluster.yaml** to **xp/workload-clusters/deploy/workload1-cluster.yaml**
3. Commit and push changes to your branch
    - `git add .`
    - `git commit -m "your message"`
    - `git push`

- After 1-2 minutes a new cluster should start creating
    - `kubectl get nkpclusters -A` [new cluster should be in list]
    - `kubectl get providers.kubernetes` [new provider config with the clusters name]
    - Showcase the gatekeeper security policy that has been created on the workload cluster ...
        - Generate a kubeconfig for the new workload cluster:
            - `nkp get kubeconfig --cluster-name ws-1-workload-1 -n workspace-1 > ~/.kube/ws-1-workload-1.conf`
        - Add to kubeconfig
            - `KUBECONFIG=~/.kube/config:~/.kube/ws-1-workload-1.conf kubectl config view --flatten > /tmp/merged-config && mv /tmp/merged-config ~/.kube/config`
mv ~/.kube/config.merged ~/.kube/config
        -  Switch kubectl context to the workload cluster
        - `kubectl --kubeconfig ~/.kube/workload-1.conf get constrainttemplates`
        - `kubectl --kubeconfig ~/.kube/workload-1.conf get k8sdisallowlatesttag`
    - Try to run a pod on the new workload cluster with the latest tag
        - Look at policies/test/nginx-pod.yaml and make sure the correct image is being used, initially we want to use the one with the latest tag
        - Run the pod `kubectl apply -f policies/test/nginx-pod.yaml` It should fail a policy error.
        - Modify policies/test/nginx-pod.yaml to use the non-latest tag image.
        - Run the pod `kubectl apply -f policies/test/nginx-pod.yaml` It should be scheduled and started in the default namespace.

#### Details on Setup

Within the repo there are two folders 0-deploy and 0-stagging. As mentioned, anything in the 0-deploy folder will be deployed. There are two examples included.

#### Why this is a strength of NKP

- Deploy crossplane and all custom apis to management cluster (not all worklaod clusters)
- Workload clusters do not need to store all API definitions or setup multiple GitOps projects
- Create clusters with custom APIs utilizing crossplane compositions and CAPI APIs.
- NKP will automatically deploy a working version of gatekeeper to all workload clusters
- Automatically deploy policy or any other type of object as desired


