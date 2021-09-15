# FC Oracle OCI OKE Sample Architecture

This repo is the result of a self-training hands-on exercise.
It contains scripts, additional configurations and instructions to set up an OKE (Oracle Kubernetes Engine) environment, with some additional services, features, and sample deployments.

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
Therefore, PLEASE CREATE IN ORDER, AND DESTROY IN REVERSE ORDER

   Create      100-fr   -->  200-core

   Destroy    200-core -->  100-fr    
    

### Terraform VARIABLE SCOPES

Each VCN is a component.
Variables for each component are generally defined (variables.tf) and assigned (terraform.tfvars) in the component root directory.

In addition, the following scopes can be used, setting values in the proper file (values will OVERRIDE what is in the root directory).

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

```
export TFENV=dev

export TFREGION=eu-frankfurt-1
```

Edit bashrc file

```
vi ~/.bashrc

`######Add these lines
alias tinit="terraform init -var-file=./../g.tfvars -var-file=./$TFENV/$TFREGION/cer.tfvars -var-file=./$TFENV/ce.tfvars -var-file=./../vars/envs/$TFENV/e.tfvars -var-file=./../vars/regions/$TFREGION/r.tfvars"

alias tplan="terraform plan -var-file=./../g.tfvars -var-file=./$TFENV/$TFREGION/cer.tfvars -var-file=./$TFENV/ce.tfvars -var-file=./../vars/envs/$TFENV/e.tfvars -var-file=./../vars/regions/$TFREGION/r.tfvars"

alias tapply="terraform apply  -var-file=./../g.tfvars -var-file=./$TFENV/$TFREGION/cer.tfvars -var-file=./$TFENV/ce.tfvars -var-file=./../vars/envs/$TFENV/e.tfvars -var-file=./../vars/regions/$TFREGION/r.tfvars"``
```



```
source ~/.bashrc
```

## 

## Layer 100-FR Provisioning

### Running Terraform

cd  repo-root  // wherever is on your machine

cd 100-fr

edit sec.auto.tfvars
(see template file, set required variables values)



```
export TFENV=dev

export TFREGION=eu-frankfurt-1

source  ~/.bashrc   //ALWAYS source after updating env variables!
```

Run Terraform now.

```
tinit

tplan

tapply

Apply complete! Resources: 31 added, 0 changed, 0 destroyed.
Outputs:
(..)

```



SAVE OUTPUT (may be useful later on), REPLACING CURRENT TIME IN FILE NAME

terraform output > tf-output-TIME.txt

(example: terraform output tf-output-202109100924.txt)



Notice that an OCI MySql Service instance has been provisioned also.



### Accessing the environment

You can notice the output includes:
ssh_to_operator = "ssh -i ~/keys/ssh-key-2021-07-01.key -J opc@xxx.yyy.227.241 opc@zzz.www.0.6"

SSH TO OPERATOR THROUGH BASTION
Insert "-o StrictHostKeyChecking=no" option in the above command. Your IP addresses will be different, of course.

- BASTION Public IP
- OPERATOR Private IP

```
ssh -o StrictHostKeyChecking=no  -i ~/keys/ssh-key-2021-07-01.key -J opc@130.61.178.195 opc@10.0.0.6

(..)
Are you sure you want to continue connecting (yes/no)? yes

```

### 

### Test KUBECTL connection

```
[opc@dev-operator ~]$ kubectl get nodes

NAME           STATUS   ROLES   AGE   VERSION
10.0.115.141   Ready    node    2d    v1.20.8
10.0.119.225   Ready    node    2d    v1.20.8
Make note of nodes IP ADRESSES
```



If you want to enable kubectl autocompletion, you find instructions here [bash auto-completion on Linux | Kubernetes](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)



Run Node Doctor
---------------

Login to a node through BASTION host (your addresses will differ).

```
ssh -o StrictHostKeyChecking=no -i ~/keys/ssh-key-2021-07-01.key -J opc@130.61.113.107 opc@10.0.115.141
```

1. Print troubleshooting output that identifies potential problem areas, with links to documentation to address those areas.

```
sudo /usr/local/bin/node-doctor.sh --check 
```

2. Gather system information in a bundle. If needed, My Oracle Support (MOS) provides instructions to upload the bundle to a support ticket.

```
sudo /usr/local/bin/node-doctor.sh --generate
```



## Set up OCI Logging for containers

In OCI console, check agent for oke workers:

Open the navigation menu and click Compute. Under Compute, click Instances.
Click the oke worker node instance that you're interested in.
Click the Oracle Cloud Agent tab.
Confirm that the Compute Instance Monitoring plugin is enabled, and all plugins are running.



**Create a dynamic group**
Use nodepool compartment id.


Create a dynamic group with a rule that includes worker nodes in the
 cluster's node pools as target hosts

Name fctfoke-workernodes 

`instance.compartment.id = 'ocid1.tenancy.oc1..xxxxxxxxxxx'`



**Create policy**

Use nodepool compartment id.




Create a new policy

Name allow-workers-to-log

`allow dynamic-group fctfoke-workernodes to use log-content in compartment id ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`



**Create log group**

Name fctfoke-lg



**Create log**

Name fctfoke-log

Create new configuration
   Select dynamic group: fctfoke-workernodes
   Log path:  `/var/log/containers/*`



Deploy WORDPRESS, connect to MySQL Service
--------------------------

### Create *polls* schema within MySQL SERVICE DB

Still working on the operator VM, install mysql

`sudo yum install mysql-shell `



// Command template will be 
// mysqlsh Username@IPAddressOfMySQLDBSystemEndpoint 

//mysqlsh adminUser@10.0.3.8  
//PASSWORD: BEstrO0ng_#11

```
opc@dev-operator ~]$ mysqlsh adminUser@10.0.3.8 
Please provide the password for 'adminUser@10.0.3.8': *************
MySQL Shell 8.0.26`
```

Create db schema

```
\sql CREATE DATABASE polls;

Query OK, 1 row affected (0.0038 sec)


\quit
```



### Clone this github repo on operator VM

```
git clone https://REPO-URL`
```

Set KUBECONFIG absolute path

```
export KUBECONFIG=REPO-ROOT/100-fr/generated/kubeconfig
```

Go to K8S WORDPRESS manifest folder 

`cd REPO-ROOT/100-fr/k8s/wp/`

### Apply k8s manifest files

MySql external service

```
[opc@dev-operator wp]$ kubectl apply -f svc-mysql.yaml 

service/external-mysql-service created
endpoints/external-mysql-service created
```

Wordpress file system, deployment and service

```
[opc@dev-operator wp]$ kubectl apply -f wp.yaml 

service/wordpress created
persistentvolumeclaim/wp-pv-claim created
deployment.apps/wordpress created
```

### Test WORDPRESS

Check services, wait for EXTERNAL-IP (may be 'pending' for a while)

```
[opc@dev-operator wp]$ kubectl get svc

NAME                     TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
external-mysql-service   ClusterIP      10.96.104.164   <none>           3306/TCP       81s
kubernetes               ClusterIP      10.96.0.1       <none>           443/TCP        29m
wordpress                LoadBalancer   10.96.192.55    129.159.243.47   80:30952/TCP   40s

```



GO TO LoadBalancer EXTERNAL-IP address, using a browser

`http://129.159.243.47`

WordPress website should be reached!

Create user and initialize WP site.



**REMINDER**

When destroyng this component, delete load balancer in k8s using kubectl, before terraform destroy. 

`[opc@dev-operator wp]$ kubectl delete service wordpress `



If you forget, you can also delete the LB using OCI console



Then, you need to run "terraform destroy" again, using "tdestroy" alias.



## Check container logs in OCI Logging

In OCI Console, select Observability >> Logs

Select the OKE nodepool compartment

Click on "fcoke-log" Log Name

Explore the log items. You should see WordPress requests logged, like the following (truncated).



```
{
  "datetime": 1631716205188,
  "logContent": {
    "data": {
      "message": "2021-09-15T14:30:04.242933438+00:00 stdout F [2021-09-15T14:30:03.677Z] \"POST /wp-admin/admin-ajax.php HTTP/1.1\" 200 

(..)

```



### Ingress Controller sample components

The ingress controller test installation comprises:

- An ingress controller deployment called nginx-ingress-controller. 
  The deployment deploys an image that contains the binary for the ingress controller and Nginx. 
  The binary (a kubernetes controller) manipulates and reloads the /etc/nginx/nginx.conf configuration file when an ingress is created in Kubernetes.
  Nginx upstreams point to services that match specified selectors.
- An ingress controller service called ingress-nginx. 
  The service exposes the ingress controller deployment as a OCI LoadBalancer type service. 
  Because Container Engine for Kubernetes uses an Oracle Cloud Infrastructure integration/cloud-provider, a load balancer will be dynamically created with the correct nodes configured as a backend set.


The hello-world backend test deployment comprises:

- A backend deployment called docker-hello-world. This is done by using a stock hello-world image that serves the minimum required routes for a default backend.
- A backend service called docker-hello-world-svc.The service exposes the backend deployment for consumption by the ingress controller deployment.
  
  

### Setting Up the Example Ingress Controller

1. If you haven't already done so, follow the steps to set up the cluster's kubeconfig configuration file. 
   
          export KUBECONFIG=REPO-ROOT/100-fr/generated/kubeconfig

Creating the Service Account, and the Ingress Controller

1. Run the following commands to create the nginx-ingress-controller ingress controller deployment, along with the Kubernetes RBAC roles and bindings. 
   
   First, download the manifest file.
   
           wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/cloud/deploy.yaml

Edit the file "deploy.yaml", changing the following line (to allow multi-node clusters):


                   OLD:   externalTrafficPolicy: Local

                   NEW:  externalTrafficPolicy: Cluster



Apply the deploy.yaml file

```
     kubectl apply -f deploy.yaml
```

To check if the ingress controller pods have started, run the following command:

                 kubectl get pods -n ingress-nginx \
                      -l app.kubernetes.io/name=ingress-ng

To detect which version of the ingress controller is running, exec into the pod and run nginx-ingress-controller --version.

                 POD_NAMESPACE=ingress-nginx
                 POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
                 kubectl exec -it $POD_NAME -n $POD_NAMESPACE -- /nginx-ingress-controller --version

Verify that the ingress-nginx Ingress Controller Service is Running as a Load Balancer Service. View the list of running services by entering:

```
      get svc ingress-nginx-controller -n ingress-nginx   
```


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



Set up Web Application Firewall (WAF)
-------------------------------

Before creating the WAF policy, you need to know the public IP address EXTERNALIP of the load balancer already been deployed for your Ingress resource (see above).

To secure your application using WAF, first, you need to create a WAF policy.

In to the Oracle Cloud Infrastructure console, go to Security and click WAF Policies.
If prompted, pick a compartment where the WAF policy should be created.
Click Create WAF Policy.
In the Create WAF Policy dialog box, enter the fields as follows:

Policy Name                              fctfoke Policy

Primary Domain                       fctkoke.com

Additional Domains                 blank

Origin Name                             fctfoke Load Balancer

URI                                              EXTERNALIP // of Ingress LB service



Look in the policy OCI Console web page, at the top, for a message like

    *Visit your DNS provider and add your CNAME fctfoke-com.o.waas.oci.oraclecloud.net to your domain's DNS configuration. Learn More*

Make note of the CNAME  (example "fctfoke-com.o.waas.oci.oraclecloud.net")

Identify one (there may be several) network IP address for the CNAME.

nslookup CNAME



Example:

```
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
A real production environment would require a proper setup for DNS in OCI. 
```

Here will just resove the name locally, just to test the WAF settings.

Select any single address from the Non-authoritative answer section of your nslookup, and create a hosts entry for the example primary domain in the /etc/hosts file of your client machine(s) as the following:



    New hosts file entry (use your IP address):

```
192.29.56.104                fctfoke-com
```

In your policy page, select Access Control in the lower left menu.
Access Rules >> Create Access Rule

   Action: Show CAPTCHA [leave all defaults]
   Conditions: HTTP Method is  GET
Save Changes

Wait 15 minutes

Try to access your CNAME host

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

`kubectl get nodes`

 (see your nodes IPs)


`kubectl drain  10.0.111.219  --ignore-daemonsets=false`

Leave only one node active.



**Deploy Pods and Services**
Hint: you may want to give a look at the manifests before applying them. You can quicly show them using the curl command.




`cd REPO_ROOT/100-fr/k8s/calico`



Create stars namespace

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/00-namespace.yaml`

Create backend app and service in stars

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/02-backend.yaml`

Create frontend app and service in stars

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/03-frontend.yaml`

Create client app and service in client namespace

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/04-client.yaml`



Deploy management-ui app and service in management-ui namespace, and make it reachable from Internet clients

Dowload the file
wget https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/manifests/01-management-ui.yaml

Edit file - so that we can access the UI from any client - making the following changes (keep indentation as-is in the yaml file).

  OLD:  type: NodePort
  NEW   type: LoadBalancer

  OLD   - port: 9001 
  NEW   - port: 80

`kubectl create -f  01-management-ui.yaml`

Wait for all the pods to enter Running state.

`kubectl get pods --all-namespaces `

Get LoadBalancer external address EXTERNAL-IP

```
kubectl get svc -n management-ui
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
management-ui   LoadBalancer   10.96.24.62   129.159.241.83   80:30002/TCP   60s
```



You can now view the UI by visiting http://EXTERNAL-IP in a browser.
By default, any-to-any access is allowed, as monitored by the UI management console.



   backend ->   Node “B”
   frontend ->  Node “F”
   client ->         Node “C”



**Set a deny-all default.**
Running the following commands will prevent all access to the frontend, backend, and client Services.

The manifest denies all communication to all Pods.



```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
spec:
  podSelector:
    matchLabels: {}
```



We first apply it to the stars namespace.

`kubectl create -n stars -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/default-deny.yaml`

We hen apply it to the client namespace also.

`kubectl create -n client -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/default-deny.yaml`



Refresh the management UI (it may take up to 10 seconds for changes to be reflected in the UI). Now that we’ve enabled isolation, the UI can no longer access the pods, and so they will no longer show up in the UI.



**Create Network Policies to allow traffic from UI**

Apply the following YAMLs to allow access from the management UI.

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/allow-ui.yaml`

Now management-ui Pods can access Pods in stars namespace



`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/allow-ui-client.yaml`

With that, we now allowed management-ui Pods access to Pods in stars namespace



After a few seconds, refresh the UI - it should now show the Services, but they should not be able to access each other any more.



**Create Network Policies to allow selected traffic between pods**

Apply the backend-policy.yaml file to allow traffic from the frontend to the backend

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/backend-policy.yaml`

Finally, expose the frontend service to the client namespace

`kubectl create -f https://docs.projectcalico.org/security/tutorials/kubernetes-policy-demo/policies/frontend-policy.yaml`

Refresh the Management UI.
You can see that 

- The client can now access the frontend, but not the backend. 
- Neither the frontend nor the backend can initiate connections to the client. 
- The frontend can still access the backend.



**Cleanup**

To restart the drained cluster nodes use the following command. Use your IP addresses.

`kubectl uncordon 10.0.111.219`



You can clean up by deleting all namespaces.

`kubectl delete ns client stars management-ui`





## Istio quick tour: setup and sample configuration

In this section we install Istio in the OKE cluster and we take it for a quick spin, testing same sample deployments and configurations.


We don't provide an introduction to Istio, its features and capabilities, which are just marginally covered here, the objective being just a quick test of Istio on OKE.



### Istio installation

Download and extract the latest Istio release automatically (Linux or macOS):

```
curl -L https://istio.io/downloadIstio | sh -


% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   102  100   102    0     0     95      0  0:00:01  0:00:01 --:--:--    95
100  4549  100  4549    0     0   4016      0  0:00:01  0:00:01 --:--:--  4016

Downloading istio-1.11.2 from https://github.com/istio/istio/releases/download/1.11.2/istio-1.11.2-linux-amd64.tar.gz ...

Istio 1.11.2 Download Complete!

Istio has been successfully downloaded into the istio-1.11.2 folder on your system.

Next Steps:
See https://istio.io/latest/docs/setup/install/ to add Istio to your Kubernetes cluster.

To configure the istioctl client tool for your workstation,
add the /home/opc/fctfoke/fc03/fctfoke/100-fr/k8s/istio/istio-1.11.2/bin directory to your environment path variable with:
     export PATH="$PATH:/home/opc/fctfoke/fc03/fctfoke/100-fr/k8s/istio/istio-1.11.2/bin"

Begin the Istio pre-installation check by running:
     istioctl x precheck 

Need more information? Visit https://istio.io/latest/docs/setup/install/ 

```

Explore directories



```
ls
istio-1.11.2



cd istio-1.11.2/
[opc@h-k8s-lab-a-helidon-2020-29-10-fc istio-1.11.2]$ ls
bin  LICENSE  manifests  manifest.yaml  README.md  samples  tools

```





The installation directory contains:

- Sample applications in samples/

- The istioctl client binary in the bin/ directory.



Add the istioctl client to your path (Linux or macOS):



```
export PATH=$PWD/bin:$PATH

istioctl x precheck 

No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/

```





For this installation, we use the demo configuration profile. It’s selected to have a good set of defaults for testing, but there are other profiles for production or performance testing.



```
istioctl install --set profile=demo -y

 Istio core installed                                                                                                                                    
 Istiod installed                                                                                                                                        
 Egress gateways installed                                                                                                                               
 Ingress gateways installed                                                                                                                              
 Installation complete                                                                                                                                   
Thank you for installing Istio 1.11.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/kWULBRjUv7hHci7T6

```



Add a namespace label (to the deafult namespace) to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later

```
kubectl label namespace default istio-injection=enabled

namespace/default labeled

```



### Deploy the Bookinfo sample application



```
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```



The application displays information about a book, similar to a single catalog entry of an online book store. Displayed on the page is a description of the book, book details (ISBN, number of pages, and so on), and a few book reviews.



The Bookinfo application is broken into four separate microservices:

- productpage. The productpage microservice calls the details and reviews microservices to populate the page.

- details. The details microservice contains book information.

- reviews. The reviews microservice contains book reviews. It also calls the ratings microservice.

- ratings. The ratings microservice contains book ranking information that accompanies a book review.



![](C:\App\Projects\LIFT\Projects\oke_eks\arch\noistio.svg)



There are 3 versions of the reviews microservice:
    Version v1 doesn’t call the ratings service.
    Version v2 calls the ratings service, and displays each rating as 1 to 5 black stars.
    Version v3 calls the ratings service, and displays each rating as 1 to 5 red stars.



The application will start. As each pod becomes ready, the Istio sidecar will be deployed along with it, so that each pod reports 2/2 containers.



```
kubectl get pods

NAME                              READY   STATUS    RESTARTS   AGE
details-v1-79f774bdb9-l6tgh       2/2     Running   0          7m35s
productpage-v1-6b746f74dc-hkbcl   2/2     Running   0          7m33s
ratings-v1-b6994bb9-hgwtn         2/2     Running   0          7m34s
reviews-v1-545db77b95-wzxch       2/2     Running   0          7m35s
reviews-v2-7bf8c9648f-l8tn8       2/2     Running   0          7m35s
reviews-v3-84779c7bbc-6pslz       2/2     Running   0          7m35s

```



Re-run the previous command and wait until all pods report READY 2/2 and STATUS Running before you go to the next step. This might take a few minutes depending on your platform.

All services are internal ClusterIP so far.

```
kubectl get services

NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.96.17.216    <none>        9080/TCP   5m33s
kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP    27h
productpage   ClusterIP   10.96.190.98    <none>        9080/TCP   5m33s
ratings       ClusterIP   10.96.17.15     <none>        9080/TCP   5m33s
reviews       ClusterIP   10.96.230.122   <none>        9080/TCP   5m33s



```

Verify everything is working correctly up to this point. 
Run this command to see if the app is running inside the cluster and serving HTML pages by checking for the page title in the response.

```
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

<title>Simple Bookstore App</title>

```



### Open the application to outside traffic

The Bookinfo application is deployed but not accessible from the outside. To make it accessible, you need to create an Istio Ingress Gateway, which maps a path to a route at the edge of your mesh.

We have already a productpage ClusterIP service exposed internally.


1. We will create a bookinfo VirtualService to map requests with seected paths to the productpage service.

2. The bookinfo VirtualService will be exposed externally thru the bookinfo-gateway


The 2 new objects are both defined in the bookinfo-gateway.yaml file



```
piVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:

- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "*"

---

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:

- "*"
  gateways:
- bookinfo-gateway
  http:
- match:
  - uri:
      exact: /productpage
  - uri:
      prefix: /static
  - uri:
      exact: /login
  - uri:
      exact: /logout
  - uri:
      prefix: /api/v1/products
    route:
  - destination:
      host: productpage
      port:
         number: 9080    

```



Apply the manifest file.

```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo created

```



OKE supports external load balancers which get assigned to istio gateways, as you can check using the following command, which shows an EXTERNAL-IP available for extarnal traffic.

```
kubectl get svc istio-ingressgateway -n istio-system

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.96.245.190   152.70.183.175   15021:30818/TCP,80:31939/TCP,443:30577/TCP,31400:30769/TCP,15443:32662/TCP   35m

```

Follow these instructions to set the INGRESS_HOST and INGRESS_PORT variables for accessing the gateway, extracting the values from the json "get -o" descriptors

```
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
```

Check the values have been set.

```
env | grep INGRESS

INGRESS_PORT=80
SECURE_INGRESS_PORT=443
INGRESS_HOST=152.70.183.175

```

Set GATEWAY_URL

```
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "$GATEWAY_URL"

152.70.183.175:80

```

Verify external access.

Run the following command to retrieve the external address of the Bookinfo application.

```
echo "http://$GATEWAY_URL/productpage"

http://152.70.183.175:80/productpage

```

Paste the output from the previous command into your web browser and confirm that the Bookinfo product page is displayed.



### Install addon tools/frameworks: Kiali dashboard, along with Prometheus, Grafana, and Jaeger.

```
kubectl apply -f samples/addons

serviceaccount/grafana created
configmap/grafana created
service/grafana created
deployment.apps/grafana configured
configmap/istio-grafana-dashboards configured
(..)

kubectl rollout status deployment/kiali -n istio-system

Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
deployment "kiali" successfully rolled out

```



We can now visualize the Kialy dashboard.
<u>This requires X11, VNC or any other graphical display access to your machine.
If not available, yoy can skip this step.</u>



To see trace data, you must send requests to your service. The number of requests depends on Istio’s sampling rate. You set this rate when you install Istio. The default sampling rate is 1%. You need to send at least 100 requests before the first trace is visible. To send 200 requests to the productpage service, use the following command (it will take few minutes):

```
$ for i in $(seq 1 300); do curl -s -o /dev/null "http://$GATEWAY_URL/productpage"; done
```

Now open the dashboard

```
istioctl dashboard kiali
```

In the left navigation menu, select Graph and in the Namespace drop down, select default.
On the upper right, select "Last 1h", then refresh.

The Kiali dashboard shows an overview of your mesh with the relationships between the services in the Bookinfo sample application. It also provides filters to visualize the traffic flow.

Hit control-C in your terminal to close the dashboard



### Request Routing with Istio

Retrieve the BookInfo url used before, and open in an external browser

http://152.70.183.175:80/productpage

Refresh several times. You’ll notice that sometimes the book review output contains star ratings and other times it does not. This is because without an explicit default service version to route to, Istio routes requests to all available versions in a round robin fashion.

To route to one version only, you apply virtual services that set the default version for the microservices. In this case, the virtual services will route all traffic to v1 of each microservice.

For this, we create destination rules, which maps pod labels to subsets, as the following snippet shows

```
 spec:
    host: reviews
    subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        version: v2
      name: v2
    - labels:
        version: v3
      name: v3
```



```
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```



Then we create virtual services to select the proper subset, by name (v1). See the following snippet.

```
  spec: 
    hosts:
    - reviews
    http:
    - route:
      - destination:
          host: reviews
          subset: v1
```



```
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```



To visualize the objects we just created use these commands.

```
 kubectl get destinationrules -o yaml
 kubectl get virtualservices -o yaml
```

You can easily test the new configuration by once again refreshing the /productpage of the Bookinfo app.


Notice that the reviews part of the page displays with no rating stars, no matter how many times you refresh. This is because you configured Istio to route all traffic for the reviews service to the version reviews:v1 and this version of the service does not access the star ratings service.



When you’re finished experimenting with the Bookinfo sample, uninstall and clean it up using the following instructions:

    samples/bookinfo/platform/kube/cleanup.sh

To confirm [default] namespace hit enter.



## Provision component/layer 200 CORE

These are the steps to create the second layer, with a different VCN, Local Peering Gateway with the first layer, and its own OKE cluster

```
cd REPO-ROOT

cd 200-core
```

edit sec.auto.tfvars

(set variables values)   



// env setup - not necessary, if already done

```
export TFENV=dev
export TFREGION=eu-frankfurt-1

source  ~/.bashrc   // ALWAYS, after setting env variables
```



Run Terraform now.

```
tinit

tplan

tapply
```





## CLEAN UP

PLEASE DESTROY IN REVERSE ORDER



1. 200-core

2. 100-fr 



The steps to clean up are:

Go to repo root directory
If needed, repeat initial Terraform setup, (env variables and init script sourcing), then enter:

```
cd 200-core
tdestroy

cd ../100-fr
tdestroy
```







                                           *F. Costa Sep 2021*
