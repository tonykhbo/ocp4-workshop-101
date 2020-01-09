
### Developing and Managing the App

In this lab we will explore some of the common activities undertaken by developers working in OpenShift. You will become familiar with how to use environment variables, secrets, build configurations, and more. Let's look at some of the basic things a developer might care about for a deployed app.

#### See the app in action and inspect some details

There is no more ambiguity or confusion about where the app came from. OpenShift provides traceability for your running deployment back to the docker image and the registry it came from, as well as (for images built by OpenShift) back to the exact source code branch and commit. Let's take a look at that.

##### CLI Instructions (Option 1)

See the status of your current project. In this case it will show the demojam service (svc) with a nested deployment config (dc) along with some more info that you can ignore for now
In the terminal run the following command:

```execute
oc status
```
<br>

Notice under the template section it lists the containers it wants to deploy along with the path to the container image:

```execute
oc describe dc/demojam-git
```

>There are a few other ways you could get to this information. If you are feeling adventurous, you might want to describe the replication controller (oc describe rc -l app=dc-metro-map), the image stream (oc describe is -l app=dc-metro-map) or the running pod itself (oc describe pod -l app=dc-metro-map).

#### Getting into a pod

There are situations when you might want to jump into a running pod, and OpenShift lets you do that pretty easily. We set some environment variables and secrets in this lab, let's jump onto our pod to inspect them.

##### CLI Instructions (Option 1)

In the terminal run the following command:

```execute
oc get pods
```
<br>

Find the pod name for your Running pod:

```
oc exec -it [POD NAME] /bin/bash

```

<br>

You are now interactively attached to the container in your pod. Let's look for the environment variables we set:

```
ls

```

<br>

```execute
exit
```
<br>

##### Web Console Instructions (Option 2)

<br>

#### Good work, let's clean this up

Let's clean up all this to get ready for the next lab:

```execute
oc delete all -l app=demojam
```

<br>

#### Summary

In this lab you've seen how to trace running software back to its roots, how to see details on the pods running your software, how to update deployment configurations, how to inspect logs files, how to set environment variables consistently across your environment, and how to interactively attach to running containers. All these things should come in handy for any developer working in an OpenShift platform.
