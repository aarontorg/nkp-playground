#! /bin/bash

export ns = $1

kubectl get workspaceroles -n $ns -o name | xargs -I {} kubectl -n torg-cluster2 patch {} --type merge -p '{"metadata":{"finalizers":[]}}'
kubectl get federatedsecrets -n $ns -o name | xargs -I {} kubectl -n torg-cluster2 patch {} --type merge -p '{"metadata":{"finalizers":[]}}'
kubectl get federatedconfigmaps -n $ns -o name | xargs -I {} kubectl -n torg-cluster2 patch {} --type merge -p '{"metadata":{"finalizers":[]}}'
kubectl get federatednamespaces -n $ns -o name | xargs -I {} kubectl -n torg-cluster2 patch {} --type merge -p '{"metadata":{"finalizers":[]}}'