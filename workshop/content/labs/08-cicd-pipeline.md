### CI/CD Defined

In modern software projects many teams utilize the concept of Continuous Integration (CI) and Continuous Delivery (CD). By setting up a tool chain that continuously builds, tests, and stages software releases, a team can ensure that their product can be reliably released at any time. OpenShift can be an enabler in the creation and management of this tool chain.

In this lab we walk through creating a simple example of a CI/CD pipeline utlizing Jenkins, all running on top of OpenShift! The Jenkins job will trigger OpenShift to build and deploy a test version of the application, validate that the deployment works, and then tag the test version into production.

#### Create a New Project

##### *CLI Instructions (Option 1)*

Create the project cicd-%username%

```execute
oc new-project cicd-%username%
```

##### *Web Console Instructions (Option 2)*

In the Admin View, click on "Home" and then click on "Projects" in the drop down. 

Click on "Create Project" and name it cicd-%username%: 

![create_prj](images/lab8_workshop_create_prj.png)

#### Use the cicd-%username% project 

##### *CLI Instructions*

```execute
oc project cicd-%username%
```

#### Instantiate a Jenkins server in your project

##### *CLI Instructions (Option 1)*

```execute
oc new-app jenkins-ephemeral
```

##### *Web Console Instructions (Option 2)*

From the Developer View, select your project, cicd-%username%.

Then click on "+Add" and then click on "From Catalog": 

![from_catalog](images/lab8_workshop_catalog.png)

In the catalog, search for jenkins or scroll down to find it: 

![catalog_jenkins](images/lab8_workshop_catalog_jenkins.png)

Click on Jenkins, click "Instantiate Template". 

Change Memory Limits to 512Mi and leave the rest of the fields as the default: 

![jenkins_create](images/lab8_workshop_jenkins_create.png)

Click "Create" at the bottom

<br>

#### Create a sample application config

##### *CLI Instructions*

Use the "oc new-app" command to create a simple nodejs application from a template file:

```execute
oc new-app -f https://raw.githubusercontent.com/tonykhbo/ocp4-workshop-101/master/workshop_101_jenkins_template.json
```

<!-- ##### *Web Console Instructions (Option 2)*

From the Developer View, select your project, cicd-%username%.

Then click on "+Add" and then click on "YAML"

![add_jenkins_template_json](images/lab8_workshop_jenkins_add_template_json.png)

Navigate to https://raw.githubusercontent.com/tonykhbo/ocp4-workshop-101/master/workshop_101_jenkins_template.json

Copy the contents of the raw .json file and paste it into Openshift:

![copy_paste_template](images/lab8_workshop_template_copy_paste.png) -->

In Admin View > Home > Projects > cicd-%username% > Workloads , you should see a nodejs-helloworld-app : 

![jenkins_njs_workload](images/lab8_workshop_jenkins_nodejs_created.png)



#### Get Jenkins route

##### *CLI Instructions (Option 1)*

Get the route to the Jenkins server. 

```execute
oc get route
```

Your HOST/PORT values will differ from the example below:

```
tonybo@macbook-2 ~ % oc get route
NAME       HOST/PORT                                                            PATH   SERVICES   PORT    TERMINATION     WILDCARD
frontend   frontend-cicd-tonykhbo.apps.us-east-1.starter.openshift-online.com          frontend   <all>   edge            None
jenkins    jenkins-cicd-tonykhbo.apps.us-east-1.starter.openshift-online.com           jenkins    <all>   edge/Redirect   None
```

##### *Web Console Instructions (Option 2)*

Navigate to Admin View > Home > Projects > Workloads > Jenkins > Resources and scroll down to see the route. 

It should be 
```
https://jenkins-%project_namespace%.%console_url%
```

![jenkins_route](images/lab8_workshop_jenkins_route.png)

Navigate to the route in your browser

#### Log into Jenkins

Select "Login with Openshift" from jenkins login page:

![jenkins_login](images/lab8_jenkins_login.png)

Click the "Allow selected permissions" button and you should be brought to the jenkins dashboard

![authorize_jenkins](images/lab8_workshop_jenkins_authorize.png)

#### Create a Jenkins pipeline using Openshift

We will be creating the following very simple (4) stage Jenkins pipeline.

Build the application from source.
Deploy the test version of the application.
Submit for approval, then tag the image for production, otherwise abort.
Scale the application.
The first step is to create a build configuration that is based on a Jenkins pipeline strategy. The pipeline is written in the GROOVY language using a Jenkins file format.

##### *CLI Instructions (Option 1)*

Run the following inside your terminal tab:


```execute
oc create -f - <<EOF
kind: "BuildConfig"
apiVersion: "v1"
metadata:
  name: "pipeline"
spec:
  strategy:
    jenkinsPipelineStrategy:
      jenkinsfile: |-
        pipeline {
          agent any
          stages {
            stage('buildFrontEnd') {
              steps {
                script {
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.selector("bc", "frontend").startBuild("--wait=true", "--follow")
                    }
                  }
                }
              }
            }
            stage('deployFrontEnd') {
              steps {
                script {
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.selector("dc", "frontend").rollout().latest()
                    }
                  }
                }
              }
            }
            stage('promoteToProd') {
              steps {
                script {
                  timeout(time: 15, unit: 'MINUTES') {
                    input message: "Promote to PROD?", ok: "Promote"
                  }
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.tag("origin-nodejs-sample:latest", "origin-nodejs-sample:prod")
                    }
                  }
                }
              }
            }
            stage('scaleUp') {
              steps {
                script {
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.selector("dc", "frontend-prod").scale("--replicas=2")
                    }
                  }
                }
              }
            }
          }
        }
EOF
```

Expected output:

```
buildconfig.build.openshift.io/pipeline created
```

##### *Web Console Instructions (Option 2)*

From the Developer View, select your project, cicd-%username%.

Then click on "+Add" and then click on "YAML"

![add_jenkins_template_json](images/lab8_workshop_jenkins_add_template_json.png)

Copy the following build configuration definition to your clipboard: 


```
kind: "BuildConfig"
apiVersion: "build.openshift.io/v1"
metadata:
  name: "pipeline"
spec:
  strategy:
    jenkinsPipelineStrategy:
      jenkinsfile: |-
        pipeline {
          agent any
          stages {
            stage('buildFrontEnd') {
              steps {
                script {
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.selector("bc", "frontend").startBuild("--wait=true", "--follow")
                    }
                  }
                }
              }
            }
            stage('deployFrontEnd') {
              steps {
                script {
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.selector("dc", "frontend").rollout().latest()
                    }
                  }
                }
              }
            }
            stage('promoteToProd') {
              steps {
                script {
                  timeout(time: 15, unit: 'MINUTES') {
                    input message: "Promote to PROD?", ok: "Promote"
                  }
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.tag("origin-nodejs-sample:latest", "origin-nodejs-sample:prod")
                    }
                  }
                }
              }
            }
            stage('scaleUp') {
              steps {
                script {
                  openshift.withCluster() {
                    openshift.withProject() {
                      openshift.selector("dc", "frontend-prod").scale("--replicas=2")
                    }
                  }
                }
              }
            }
          }
        }
```

Paste this build configuration definition and click "Create":

![jenkins_bc_pipeline](images/lab8_workshop_jenkins_build_config.png)

<br>

#### Start the pipeline

In the Developer View, navigate to "Builds" and click on your build config labeled "pipeline" : 

![devview_builds_pipeline](images/lab8_workshop_builds_pipeline.png)

On the right side, click on "Actions, then click on "Start Build" : 

![pipeline_startbuild](images/lab8_workshop_start_pipeline_build.png)

When the pipeline starts, OpenShift uploads the pipeline to the Jenkins server for execution. You should see the build pop up in your build config view: 

![bc_config_view_dev](images/lab8_workshop_buildstart_view.png)


As it runs, the various stages trigger OpenShift to build and deploy the frontend microservice. After a Jenkins user approves the frontend deployment, Jenkins triggers OpenShift to tag the image stream with the ":prod" tag then scales the frontend-prod deployment for (2) replicas.

The Jenkins dashboard should indicate that a new build is executing.

![jenkins_pipeline_start_view](images/lab8_workshop_build_exec_view.png)

Back in the OpenShift Web Console, watch the pipeline execute. Once the "deployFrontEnd" stage completes, you should be able to visit the route for the frontend service in a web browser.

#### Confirm both the test and production services are available

##### *CLI Instructions (Option 1)*

##### *Web Console Instructions (Option 2)*

#### Edit the pipeline

##### *CLI Instructions (Option 1)*

##### *Web Console Instructions (Option 2)*

#### Summary

In this lab you have very quickly and easily constructed a basic Build/Test/Deploy pipeline. Although our example was very basic it introduces you to a powerful DevOps feature of OpenShift through the leveraging of Jenkins. This can be extended to support complex real-world continuous delivery requirements. 

