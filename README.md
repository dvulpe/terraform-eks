# EKS terraform using blue/green approach to cluster upgrades
Having used in-place upgrades with EKS - they are really great, but sometimes it's useful to just stand up a completely
fresh cluster and switch the traffic gradually from blue to green cluster.
I am sure there are better terraform modules out there, I have used this approach to learn more about how EKS works and how
blue/green cluster upgrades could work as well.

This is a simple approach which achieves this result by using Application Load Balancer and target groups with weighted routing.

Inside the `roots` folder there are a few terraform roots (as opposed to terraform modules) that need to be applied:
* `base` is the one that stands up the VPC, security groups as well as the ingress (ALB, blue and green target groups)
* `variant-blue` is the blue cluster
* `variant-green` is the green cluster

Inside `modules` we have:
* `eks-cluster` - this is the module responsible with standing up the EKS cluster and any cluster-specific IAM roles (such as autoscaler and worker IAM roles) 
   as well as the `aws-auth` config map in `kube-system`. This module is also responsible with setting up the OIDC provider 
   for service accounts so that workloads in the cluster can assume IAM roles.
* `node-group` - this module stands up a zonal autoscaling group with required node labels and taints using BottleRocket OS
* `cluster-nodegroups` - this module defines the collection of node groups to be deployed in the cluster. 
For example we have the worker node group and a monitoring node group registered with taints.
* `cluster-workloads` a flux helm chart that should be created in every variant. It's going to point flux to use the manifests from [flux-variants](https://github.com/dvulpe/flux-variants/)
* `eks-variant` - this module ties together the `eks-cluster` and the `cluster-nodegroups` module and expresses what a cluster variant looks like.
* `ingress` defines the ingress Application Load Balancer and the two target groups: blue and green
* `security-groups` defines all the security groups required in the VPC. They may be quite permissive as the focus was to 
    see the spike working rather than lock it down.
    
In order to apply it, please make sure you have `terraform 0.13`, and you have access to AWS credentials, then:

1. Apply the `base` terraform root:
```
cd roots/base
terraform plan -out deployment.plan
# inspect the plan ...
terraform apply deployment.plan
```

2. Apply the `variant-blue` root:
```
cd roots/variant-blue
terraform plan -out deployment.plan
# inspect the plan ...
terraform apply deployment.plan
```

3. Apply the `variant-green` root:
```
cd roots/variant-green
terraform plan -out deployment.plan
# inspect the plan ...
terraform apply deployment.plan
```

Open up the load balancer address
```
cd roots/base
ALB_ADDR=$(terraform output alb_address)
open http://${ALB_ADDR}
```
and you should see podinfo.

Once variant-green you can tweak the ingress weights to be 50/50 in `roots/base/ingress.tf:8` and apply `base` 
and you should see podinfo http responses coming back from both clusters.

Try shifting 100% of the traffic to green and then teardown blue. Try standing up blue again, shift the traffic and 
tear down green. 

What can you do next?
- create an AWS managed certificate and add it to the ALB
- run a meaningful workload behind the ALB and expose it outside with an ingress
- use OIDC authentication at the ALB level for private workloads


