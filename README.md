# DigitalOcean-Kubernetes-Multi-Regions-Load-Balancing
<!-- <div id="top"></div> -->
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
<!-- [![Contributors][contributors-shield]][contributors-url] -->
<!-- [![Forks][forks-shield]][forks-url] -->
<!-- [![Stargazers][stars-shield]][stars-url] -->
<!-- [![Issues][issues-shield]][issues-url] -->
<!-- [![MIT License][license-shield]][license-url] -->
<!-- [![LinkedIn][linkedin-shield]][linkedin-url] -->



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://saucelabs.com/resources/topics/api-testing">
    <img src="https://www.digitalocean.com/_next/static/media/logo.87a8f3b8.svg" alt="Logo" >
  </a>

<h3 align="center">DigitalOcean | Multi-Regions DOKS Cluster Load Balancing Tutorial </h3>

  <p align="center">
    This tutorial is mainly about how to setup multi-region DOKS clusters with geographical load balancing
    <br />
    <a href="https://www.digitalocean.com/community/tags/kubernetes"><strong>Explore more Kubernetes tutorials»</strong></a>
    <br />
    <br />
  
  </p>
</div>

<!-- ABOUT THE PROJECT -->
<!-- ## About The Project -->

<!-- [![Product Name Screen Shot][product-screenshot]](https://example.com) -->




<!--  -->
<!-- ### Built With -->
<!--  -->
<!-- * [Next.js](https://nextjs.org/) -->
<!-- * [React.js](https://reactjs.org/) -->
<!-- * [Vue.js](https://vuejs.org/) -->
<!-- * [Angular](https://angular.io/) -->
<!-- * [Svelte](https://svelte.dev/) -->
<!-- * [Laravel](https://laravel.com) -->
<!-- * [Bootstrap](https://getbootstrap.com) -->
<!-- * [JQuery](https://jquery.com) -->
<!--  -->
<!-- <p align="right">(<a href="#top">back to top</a>)</p> -->



<!-- GETTING STARTED -->
# Getting Started


## Architecture diagram
![architecture](./assets/architecture.png)

## Introduction

In this tutorial, we'll guide you through the process of setting up global load balancing for a multi-regions Kubernetes cluster using Cloudflare as the global load balancer and DigitalOcean's Managed Kubernetes product, DOKS. We'll set up the example clusters in the London and Sydney datacenters. Kubernetes is an open-source platform for automating deployment, scaling, and management of containerized applications, and is widely used for modernizing application infrastructure. By deploying a Kubernetes cluster in multiple regions and using Cloudflare as the global load balancer, you can ensure high availability and low latency for your users, regardless of their location. We'll show you how to configure Cloudflare and DOKS to optimize performance and reliability for your users.


## Prerequisites

Below are what you will need before using Sauce Labs's API testing platform,
1. A DigitalOcean account ([Log in](https://cloud.digitalocean.com/login) or sign up by my [referal link](https://m.do.co/c/7c424df00920))
2. A Cloudflare account
3. doctl CLI([tutorial](https://docs.digitalocean.com/reference/doctl/how-to/install/))
4. Docker
5. Kubernetes
6. Your domain


## Environmental setup







# 1. DigitalOcean - Create DOKS clustersin multi-regions

The goal of this step is to create two Kubernetes clusters using DigitalOcean's Managed Kubernetes (DOKS) service in different datacenters, London and Sydney, and deploy a public facing nginx service.

## Create new DOKS clusters

To make it simple and quick, you can follow this [video](https://www.youtube.com/watch?v=k50reywjO5U) tutorial and create the first cluster in just 10 minutes.

Once you have created the first cluster(London), repeat the same process to create the second cluster in the different datacenter (Sydney).

## Deploy a public-facing nginx service

To deploy the service, follow these steps:

```sh
cd doks-example/

# Setup the datacenter env to lon1 for London-based cluster
export DC=lon1

# Build an new image that including lon1 text in the header
./script/docker-publish $DC

# Create a DOKS cluster at London datacenter and deploy service
./script/up $DC
```
Wait until a new window pops up. You should see a landing page similar to the following,
![lon1](./assets/lon1.png)

Repeat the same process to create a Sydney-based cluster by setting the environment variable DC to syd1:
```sh
# Setup the datacenter env to lon1 for London-based cluster
export DC=syd1

# Build an new image that including lon1 text in the header
./script/docker-publish $DC

# Create a DOKS cluster at London datacenter and deploy service
./script/up $DC

```
Wait until a new window pops up. You should see a landing page similar to the following,
![syd1](./assets/syd1.png)


# 2. Cloudflare: Setup Global Load Balancer
## Add site to Cloudflare
To create a new Cloudflare site, follow these steps:

1. Add a site to work with. For this tutorial, we will use `isfusion.cloud` as the domain.

2. Add a host entry. You can add any random entry that will not be used.

3. Use a root domain name instead of a subdomain

4. To begin, select the "Add Site" link located in the top right corner of the page.

![add-site-cloudflare](./assets/add-site-cloudflare.png)

## Turn on load-balancing

Go to the Traffic section in the menu and choose "Load Balancing"
![turn-on-lb](./assets/turn-on-lb.png)

The wizard will ask you to choose a subscription if you don't already have one. We suggest picking the cheapest option, which is enough for this tutorial as we only need two servers to show what Cloudflare can do. The subscription will also ask you how many regions should check the health of your servers and if you want to turn on dynamic traffic management for faster response times and geographic routing.
![subscription-plan](./assets/subscription-plan.png)

Upon completion of the previous step, you will be directed to this page.

![setting-page](./assets/setting-page.png)

Click the "Create Laod Balancer"

## Setting a hostname 

We are going to put together our endpoints and health checks to make a load balancer. We will use Cloudflare's servers as a full proxy, so all web traffic will go through them. This is the default option. Another option is just to redirect the traffic with DNS, but this won't let us use the full benefits of these platforms, like caching and keeping web traffic secure. This example will use `doks-multi-regions-cluster.isfusion.cloud` as the hostname.

![hostname](./assets/hostname.png)


## Create an Origin Pool

The first step in using Cloudflare is to decide where you want the traffic to go. This can be any group of computers that can receive traffic from the internet. The more spread out these computers are, the better it is to use a service like Cloudflare to control the traffic.

To use Kubernetes clusters as origins, they must be set up to receive traffic from the internet by having a service with an external IP address. This can be done by using a Load Balancer service or a tool called an ingress controller like NGINX. To find the IP address to use for a service, you can use the following command:

```sh
# Get all context first 
$ kubectl config get-contexts 
$ kubectl config use-contexts do-lon1-doks-lon1-multi-region-cluster
$ kubectl get services doks-example
NAME           TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
doks-example   LoadBalancer   10.245.70.99   138.68.118.154   80:31010/TCP   28h
```
![create-origin-pool](./assets/create-origin-pool.png)


## Create monitor and add notification
We need to make sure the nodes in our pool are working properly. We do this by checking their health on a regular schedule. If a node fails the check, it will be marked as not working and will not receive any traffic until it passes the check again. Sometimes nodes stop working because of upgrades or other problems. For this example, we will check if the NGINX program on each cloud is showing its default page. For more complicated situations, it's a good idea to have a special page that tests the connection to all the data sources and makes sure everything is working correctly. If we don't do this, the load balancer might think the program is still working when it's actually not.

![create-monitor](./assets/create-monitor.png)

## Traffic sterring
In this example, when we make the pool, we are using weighting to control the incoming traffic. We have two groups of computers, one in London and one in Sydney. Both groups will get the same amount of traffic (50%).

![traffic-steering](./assets/select-routing-algorithm.png)

## Custom rule(optional)
This step is optional. You can choose to set up your own rules for how the traffic is spread around the world, or you can just click "Next" and skip it.

![custom-rule](./assets/custom-rule.png)

## Review & deploy
When you have finished setting everything up, you can make your first multi-regional DOKS cluster with traffic control around the world by clicking the "Save and Deploy" button.
![review-deploy](./assets/review-deploy.png)



## Multi-regions cluster is ready!
Now you will see a new load balancer on the screen with a healthy status and other settings.

![eploy](./assets/deploy.png)


# 3. Verify The Global Load Balancing

You can verify the randomly distributed incoming traffic between London and Sydney datacenters (with a 50/50 weighting) by running some simple commands.

```sh
./verify.sh
```
You will see the following information displayed in your terminal.

```sh
<title>Welcome to DOKS @ lon1</title>
<title>Welcome to DOKS @ syd1</title>
<title>Welcome to DOKS @ lon1</title>
<title>Welcome to DOKS @ syd1</title>
<title>Welcome to DOKS @ lon1</title>
<title>Welcome to DOKS @ syd1</title>
<title>Welcome to DOKS @ syd1</title>
<title>Welcome to DOKS @ lon1</title>
<title>Welcome to DOKS @ syd1</title>
<title>Welcome to DOKS @ lon1</title>
```

# 4. Turn down everything
```sh
cd doks-example
export DC=lon1
# Select yes when you get a prompt
./script/down $DC

export DC=syd1
# Select yes when you get a prompt
./script/down $DC
```
<!-- # 5. Cost analysis -->
<!-- # Common error message and how to troubleshooting

- doctl, docker, kubectl
- container registry
- svc crashed loop
- pull images but always crash
(使用alwaypullimage policy)
(刪除registry上的檔案重新push或是用新的tagging)
-  -->

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->




<!-- CONTRIBUTING -->
<!-- ## Contributing -->
<!--  -->
<!-- <!-- <!-- <!-- Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**. --> 
<!--  -->
<!-- <!-- <!-- <!-- If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement". -->
<!-- <!-- Don't forget to give the project a star! Thanks again! --> 
<!--  -->
<!-- 1. Fork the Project -->
<!-- <!-- 2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`) --> 
<!-- <!-- 3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`) --> 
<!-- <!-- 4. Push to the Branch (`git push origin feature/AmazingFeature`) --> 
<!-- 5. Open a Pull Request -->
<!--  -->
<!-- <!-- <p align="right">(<a href="#top">back to top</a>)</p> --> 



<!-- LICENSE -->
<!-- ## License -->

<!-- Distributed under the MIT License. See `LICENSE.txt` for more information. -->

<!-- <p align="right">(<a href="#top">back to top</a>)</p> -->



<!-- CONTACT -->
# Contact

Jeff Fan - jfan@digitalocean.com

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
<!-- ## Acknowledgments -->
<!--  -->
<!-- * []() -->
<!-- * []() -->
<!-- * []() -->
<!--  -->
<!-- <p align="right">(<a href="#top">back to top</a>)</p> -->



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/github_username/repo_name.svg?style=for-the-badge
[contributors-url]: https://github.com/github_username/repo_name/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/github_username/repo_name.svg?style=for-the-badge
[forks-url]: https://github.com/github_username/repo_name/network/members
[stars-shield]: https://img.shields.io/github/stars/github_username/repo_name.svg?style=for-the-badge
[stars-url]: https://github.com/github_username/repo_name/stargazers
[issues-shield]: https://img.shields.io/github/issues/github_username/repo_name.svg?style=for-the-badge
[issues-url]: https://github.com/github_username/repo_name/issues
[license-shield]: https://img.shields.io/github/license/github_username/repo_name.svg?style=for-the-badge
[license-url]: https://github.com/github_username/repo_name/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png