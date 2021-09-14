# FC Oracle OCI OKE Sample Architecture

This repo is the result of a self-training hands-on exercise.
It contains scripts, additional configurations and instructions to set up an OKE environment, with some additional services, features, and sample deployments.

The main elements covered are:

- Two VCNs (Local Peering established), each with an OKE cluster

- Simple arrangement of the Terraform variable assignments, based on directories and environment variables, to be able to provision different environments (dev, test, prod), in different regions.

- Bastion VM and convenience Operator VM for cluster access.

- OKE Node Doctor

- Deployment of a sample WordPress app, with access to OCI MySql Service

- Calico setup and sample NetworkPolicies test

- Nginx Ingress Controller setup and samples

- Web Application Firewall (WAF), for public load balancers protection

- Istio Service Mesh installation and samples [PLANNED]

## Setting up with Terraform

### Components

From Terraform point of view, we have two *components*

   100-fr

   200-core 

They are arrenged in a LAYERED ARCHITECTURE, with 100-fr being the bottom layer
Therefore, PLEASE CREATE AND DESTROY IN REVERSE ORDER

   Create      100-fr   -->  200-core

   Destroy    200-core -->  100-fr     

### Terraform VARIABLE SCOPES

Each VCN is a component.
Variables for each component are generally defined (variables.tf) and assigned (terraform.tfvars) in the component root directory.

In addition, the following scopes can be used (values will OVERRIDE what is in the root directory).

```
GLOBAL                        -var-file=./../g.tfvars
```

```
COMPONENT-ENVIRONMENT-REGION  -var-file=./$TFENV/$TFREGION/cer.tfvars"
```

```
COMPONENT-ENVIRONMENT         -var-file=./$TFENV/ce.tfvars
```

```
ENVIRONMENT                   -var-file=./../vars/envs/$TFENV/e.tfvars
```

```
REGION                        -var-file=./../vars/regions/$TFREGION/r.tfvars
```

### Setup steps

export TFENV=dev

export TFREGION=eu-frankfurt-1

Edit bashrc file

```
vi ~/.bashrc

`######Add these lines
alias tinit="terraform init -var-file=./../g.tfvars -var-file=./$TFENV/$TFREGION/cer.tfvars -var-file=./$TFENV/ce.tfvars -var-file=./../vars/envs/$TFENV/e.tfvars -var-file=./../vars/regions/$TFREGION/r.tfvars"

alias tplan="terraform plan -var-file=./../g.tfvars -var-file=./$TFENV/$TFREGION/cer.tfvars -var-file=./$TFENV/ce.tfvars -var-file=./../vars/envs/$TFENV/e.tfvars -var-file=./../vars/regions/$TFREGION/r.tfvars"

alias tapply="terraform apply  -var-file=./../g.tfvars -var-file=./$TFENV/$TFREGION/cer.tfvars -var-file=./$TFENV/ce.tfvars -var-file=./../vars/envs/$TFENV/e.tfvars -var-file=./../vars/regions/$TFREGION/r.tfvars"``
```

source ~/.bashrc

## Layer 100-FR Provisioning

### Running Terraform

cd  repo-root  // wherever is on your machine

cd 100-fr

edit sec.auto.tfvars
(see template file, set required variables values)

export TFENV=dev

export TFREGION=eu-frankfurt-1

source  ~/.bashrc   # ALWAYS source after updating env variables!

Run Terraform now.

tinit

tplan

tapply

Apply complete! Resources: 31 added, 0 changed, 0 destroyed.
Outputs:
(..)

SAVE OUTPUT, REPLACE CURRENT TIME IN FILE NAME

terraform output > tf-output-.txt

(example: terraform output tf-output-202109100924.txt)

Notice that an OCI MySql Service instance has been provisioned also.

### Accessing the environment

You can notice the output includes:
ssh_to_operator = "ssh -i ~/keys/ssh-key-2021-07-01.key -J opc@xxx.yyy.227.241 opc@zzz.www.0.6"

SSH TO OPERATOR THROUGH BASTION
Insert "-o StrictHostKeyChecking=no" option in the above command. Your IP addresses will be different, of course.

- BASTION Public IP
- OPERATOR Private IP

ssh -o StrictHostKeyChecking=no  -i ~/keys/ssh-key-2021-07-01.key -J opc@130.61.178.195 opc@10.0.0.6

(..)
Are you sure you want to continue connecting (yes/no)? yes

### Test KUBECTL connection

[opc@dev-operator ~]$ kubectl get nodes

NAME           STATUS   ROLES   AGE   VERSION

10.0.115.141   Ready    node    2d    v1.20.8

10.0.119.225   Ready    node    2d    v1.20.8

Make note of nodes IP ADRESSES



If you want to enable kubectl autocompletion, you find instructions here [bash auto-completion on Linux | Kubernetes](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)



RUN NODE DOCTOR
---------------

Login to a node through BASTION host (your addresses will differ).

ssh -o StrictHostKeyChecking=no -i ~/keys/ssh-key-2021-07-01.key -J opc@130.61.113.107 opc@10.0.115.141

1. Print troubleshooting output that identifies potential problem areas, with links to documentation to address those areas.

sudo /usr/local/bin/node-doctor.sh --check 

2. Gather system information in a bundle. If needed, My Oracle Support (MOS) provides instructions to upload the bundle to a support ticket.

sudo /usr/local/bin/node-doctor.sh --generate

Deploy WOPRPRESS connected to OCI MySQL Service
--------------------------

### Create *polls* schema within MYSQL SERVICE DB

sudo yum install mysql-shell #mysqlsh Username@IPAddressOfMySQLDBSystemEndpoint mysqlsh adminUser@10.0.3.8 BEstrO0ng_#11

\sql CREATE DATABASE polls;
Query OK, 1 row affected (0.0038 sec)

\quit

### CLONE THIS REPO ON OPERATOR VM

 git clone https://github.com/mailbox171/<repo-name>

GO TO K8S WORDPRESS K8S MANIFEST FOLDER 
cd fctfoke-v01/100-fr/k8s/wp/

### APPLY MANIFEST .yaml FILES

[opc@dev-operator wp]$ kubectl apply -f svc-mysql.yaml 
service/external-mysql-service created
endpoints/external-mysql-service created

[opc@dev-operator wp]$ kubectl apply -f wp.yaml 
service/wordpress created
persistentvolumeclaim/wp-pv-claim created
deployment.apps/wordpress created

### Test WORDPRESS

CHECK SERVICES, WAIT FOR EXTERNAL ADDRESS (may be 'pending' for a while)

[opc@dev-operator wp]$ kubectl get svc
NAME                     TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE

external-mysql-service   ClusterIP      10.96.104.164   <none>           3306/TCP       81s

kubernetes               ClusterIP      10.96.0.1       <none>           443/TCP        29m

wordpress                LoadBalancer   10.96.192.55    129.159.243.47   80:30952/TCP   40s

GO TO ADDRESS, IN ANY INTERNET BROWSER

http://129.159.243.47

WordPress website should be reached!

**REMINDER**

When destroyng this component, delete load balancer in k8s using kubectl, before terraform destroy. 

[opc@dev-operator wp]$ kubectl delete service wordpress 

If you forget, you can also delete the LB using OCI console, then you need to run "terraform destroy" again, using "tdestroy" alias.

NGINX Ingress Controller
-------------------------------

### Ingress Controller

The ingress controller comprises:

- An ingress controller deployment called nginx-ingress-controller. 
  The deployment deploys an image that contains the binary for the ingress controller and Nginx. 
  The binary (a kubernetes controller) manipulates and reloads the /etc/nginx/nginx.conf configuration file when an ingress is created in Kubernetes.
  Nginx upstreams point to services that match specified selectors.
- An ingress controller service called ingress-nginx. 
  The service exposes the ingress controller deployment as a OCI LoadBalancer type service. 
  Because Container Engine for Kubernetes uses an Oracle Cloud Infrastructure integration/cloud-provider, a load balancer will be dynamically created with the correct nodes configured as a backend set.

Backend Components
The hello-world backend comprises:

- A backend deployment called docker-hello-world. This is done by using a stock hello-world image that serves the minimum required routes for a default backend.
- A backend service called docker-hello-world-svc.The service exposes the backend deployment for consumption by the ingress controller deployment.

### Setting Up the Example Ingress Controller

1. If you haven't already done so, follow the steps to set up the cluster's kubeconfig configuration file. No need to do this if working from the OPERATOR virtual machine.
   If working from the machine used as Terraform client, type:
   
          export KUBECONFIG=<repo-root>/100-fr/generated/kubeconfig

Creating the Service Account, and the Ingress Controller

1. Run the following command to create the nginx-ingress-controller ingress controller deployment, along with the Kubernetes RBAC roles and bindings. First download the manifest file.
   
           wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/cloud/deploy.yaml

Edit the file "deploy.yaml", changing the following line
                 OLD:  externalTrafficPolicy: Local
                 NEW:  externalTrafficPolicy: Cluster

Apply the deploy.yaml file
                 kubectl apply -f deploy.yaml

To check if the ingress controller pods have started, run the following command:

                 kubectl get pods -n ingress-nginx \
                      -l app.kubernetes.io/name=ingress-ng

To detect which version of the ingress controller is running, exec into the pod and run nginx-ingress-controller --version.

                 POD_NAMESPACE=ingress-nginx
                 POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
                 kubectl exec -it $POD_NAME -n $POD_NAMESPACE -- /nginx-ingress-controller --version

Verify that the ingress-nginx Ingress Controller Service is Running as a Load Balancer Service. View the list of running services by entering:
                get svc ingress-nginx-controller -n ingress-nginx   
The output from the above command shows the EXTERNAL-IP for the ingress-nginx Service. Make note of the external ip

### Creating a TLS Secret.

A TLS secret is used for SSL termination on the ingress controller. Output a new key to a file. For example, by entering:

                openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=nginxsvc/O=nginxsvc"

Create the TLS secret by entering: 

                kubectl create secret tls tls-secret --key tls.key --cert tls.crt

### Setting Up the Example Backend

In this section, you define a hello-world backend service and deployment.
Create the new hello-world deployment and service on nodes in the cluster by running the following command:

                kubectl apply -f hello-world-ingress.yaml

Using the Example Ingress Controller to Access the Example Backend
In this section you create an ingress to access the backend using the ingress controller.

                kubectl apply -f ingress-v1.yaml

Verify that the Example Components are Working as Expected.
To confirm the ingress-nginx service is running as a LoadBalancer service, obtain its external IP address by entering:

                kubectl get svc --all-namespaces

Sending cURL Requests to the Load Balancer
Use the external IP address of the ingress-nginx service (for example, 129.146.214.219) to open a browser, or otherwise curl an http request by entering:

                curl --trace -  http://<EXTERNALIP>

One more Ingress example
------------------------

(from https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/ )

Create a Deployment using the following command:

                kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0

Expose as service

                kubectl expose deployment web --type=NodePort --port=8080

Create ingress resource

                kubectl apply -f example-ingress.yaml

Sending cURL Requests to the Load Balancer (Hello world)

Use the same external IP address (adding the path /helloworld) of the ingress-nginx service (for example, 129.146.214.219) to open a browser, or otherwise curl an http request by entering:

                curl --trace -  http://<EXTERNALIP>/helloworld

Check the / path still works (Hello webhook world)

Use the external IP address of the ingress-nginx service (for example, 129.146.214.219) to open a browser, or otherwise curl an http request by entering:

                curl --trace -  http://<EXTERNALIP>

SET UP Web Application Firewall
-------------------------------

Before creating the WAF policy, you need to know the public IP address EXTERNALIP of the load balancer already been deployed for your Ingress resource (see above).

To secure your application using WAF, first, you need to create a WAF policy.

In to the Oracle Cloud Infrastructure console, go to Security and click WAF Policies.
If prompted, pick a compartment where the WAF policy should be created.
Click Create WAF Policy.
In the Create WAF Policy dialog box, enter the fields as follows:

Policy Name     fctfoke Policy

Primary Domain     fctkoke.com

Additional Domains     blank

Origin Name     fctfoke Load Balancer

URI             EXTERNALIP

Look in the policy web page, at the top, for a message like

    *Visit your DNS provider and add your CNAME fctfoke-com.o.waas.oci.oraclecloud.net to your domain's DNS configuration. Learn More*

Make note of the CNAME

Identify a (there may be several) network IP address for the CNAME.

nslookup CNAME

Example

    nslookup  fctfoke-com.o.waas.oci.oraclecloud.net
    
    
    Server:  fritz.box
    
    
    Address:  192.168.178.1

Non-authoritative answer:

Name:    eu-switzerland.inregion.waas.oci.oraclecloud.net

Addresses:  192.29.61.119

            192.29.56.104
    
    
            192.29.61.248

Aliases:  fctfoke-com.o.waas.oci.oraclecloud.net
          tm.inregion.waas.oci.oraclecloud.net

A real production environment would require the correct setup for DNS. Here will just resove the name locally, just to test the WAF settings.

Select any single address from the Non-authoritative answer section of the nslookup, and create a hosts entry for the example primary domain in the /etc/hosts file of your client machine(s) as the following:

hosts file entry 

```
192.29.56.104                fctfoke-com
```

In your policy page, select Access Control in the lower left menu.
Access Rules >> Create Access Rule

   Action: Show CAPTCHA [leave all defaults]
   Conditions: HTTP Method is  GET
Save Changes

Wait 15 minutes

Try to access your EXTERNALIP

    http://fctfoke.com/

You shuold be prompted with a CAPTCHA, which means the WAF is active. 



## Network Policies with Calico

Clusters you create with Container Engine for Kubernetes have flannel installed as the default CNI network provider.

Although flannel satisfies the requirements of the Kubernetes networking model, it does not support NetworkPolicy resources. If you want to enhance the security of clusters you create with Container Engine for Kubernetes by implementing network policies, you have to install and configure a network provider that does support NetworkPolicy resources. One such provider is Calico.

Network policies lets developers secure access to and from their applications using the same simple language they use to deploy them. Developers can focus on their applications without diving into low-level networking concepts.

The Kubernetes Network Policy API supports the following features:

- Policies are namespace scoped

- Policies are applied to pods using label selectors

- Policy rules can specify the traffic that is allowed to/from pods, namespaces, or CIDRs

- Policy rules can specify protocols (TCP, UDP, SCTP), named ports or port numbers



**Defaults**
If no Kubernetes network policies apply to a pod, then all traffic to/from the pod are allowed (default-allow). As a result, if you do not create any network policies, then all pods are allowed to communicate freely with all other pods. 

If one or more Kubernetes network policies apply to a pod, then only the traffic specifically defined in that network policy are allowed (default-deny).



### Running the stars example

Since this example has been designed and tested for a single-node cluster, pause all your k8s nodes (but one), using the commands:

kubectl get nodes (see your nodes IPs)
kubectl drain  10.0.111.219  --ignore-daemonsets=false

Leave only one node active.



**Deploy Pods and Services**
Hint: you may want to give a look at the manifests before applying them. You can quicly show them using the curl command.




cd REPO_ROOT/100-fr/k8s/calico



Create stars namespace

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/00-namespace.yaml

Create backend app and service in stars

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/02-backend.yaml

Create frontend app and service in stars

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/03-frontend.yaml

Create client app and service in client namespace

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/04-client.yaml



Deploy management-ui app and service in management-ui namespace, and make it reachable from Internet clients

Dowload the file
wget https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/01-management-ui.yaml

Edit file - so that we can access the UI from any client - making the following changes (keep indentation as-is in the yaml file).

  OLD:  type: NodePort
  NEW   type: LoadBalancer

  OLD   - port: 9001 
  NEW   - port: 80

kubectl create -f  01-management-ui.yaml

Wait for all the pods to enter Running state.

kubectl get pods --all-namespaces 

Get LoadBalancer external address EXTERNAL-IP

kubectl get svc -n management-ui
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
management-ui   LoadBalancer   10.96.24.62   129.159.241.83   80:30002/TCP   60s



You can now view the UI by visiting http://EXTERNAL-IP in a browser.
By default, any-to-any access is allowed, as monitored by the UI management console.



   backend ->   Node “B”
   frontend ->  Node “F”
   client ->         Node “C”



**Set a deny-all default.**
Running the following commands will prevent all access to the frontend, backend, and client Services.

The manifest denies all communication to all Pods.



kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
spec:
  podSelector:
    matchLabels: {}



We first apply it to the stars namespace.

kubectl create -n stars -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/default-deny.yaml

We hen apply it to the client namespace also.

kubectl create -n client -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/default-deny.yaml



Refresh the management UI (it may take up to 10 seconds for changes to be reflected in the UI). Now that we’ve enabled isolation, the UI can no longer access the pods, and so they will no longer show up in the UI.



**Create Network Policies to allow traffic from UI**

Apply the following YAMLs to allow access from the management UI.

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/allow-ui.yaml

Now management-ui Pods can access Pods in stars namespace



kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/allow-ui-client.yaml

With that, we now allowed management-ui Pods access to Pods in stars namespace



After a few seconds, refresh the UI - it should now show the Services, but they should not be able to access each other any more.



**Create Network Policies to allow selected traffic between pods**

Apply the backend-policy.yaml file to allow traffic from the frontend to the backend

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/backend-policy.yaml

Finally, expose the frontend service to the client namespace

kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/frontend-policy.yaml

Refresh the Management UI.
You can see that 

- The client can now access the frontend, but not the backend. 
- Neither the frontend nor the backend can initiate connections to the client. 
- The frontend can still access the backend.



**Cleanup**

To restart the drained cluster nodes use the following command. Use your IP addresses.

kubectl uncordon 10.0.111.219



You can clean up by deleting all namespaces.

kubectl delete ns client stars management-ui



## Provision component/layer 200 CORE

These are the steps to create the second layer, with a different VCN, Local Peering Gateway with the first layer, and its own OKE cluster

cd REPO-ROOT

cd 200-core

edit sec.auto.tfvars

(set variables values)   



// env setup - not necessary, if already done

export TFENV=dev

export TFREGION=eu-frankfurt-1

source  ~/.bashrc   // ALWAYS, after setting env variables



Run Terraform now.

tinit

tplan

tapply





## CLEAN UP

PLEASE DESTROY IN REVERSE ORDER

200-core

100-fr 

The steps to clean up are:

Go to repo root directory
If needed, repeat initial Terraform setup, (env variables and init script sourcing)

cd 200-core

tdestroy

 cd ../100-fr

tdestroy







                                           *F.Costa Sep 2021*
