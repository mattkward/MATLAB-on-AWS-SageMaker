# Overview

This Repo provides an approach for executing MATLAB stand-alone executables on AWS SageMaker. Amazon has a large number of repos of there own that give a more complete overview on their technologies, with this mostly filling the gap for executing MATLAB code on the platform.

Software used:
* Ubuntu
* MATLAB 2018b
* Compiler Toolbox
* Docker
* AWS Services (AWS Command Line Interface, SageMaker, S3, ECR, etc.)



# 1. SageMaker, Docker, and Folder Structure
SageMaker is AWS's Machine Learning platform and uses Jupyter Notebooks and Python. SageMaker has a few different ways of executing code, including Training Jobs and Inferences/Hosting. This guide is covering Training Jobs only but it's likely the code can be altered for Inference and Hosting. Additionally, this is assuming SageMaker's "File" input is used as opposed to "Pipe".

If you don't want to use SageMaker's built-in capabilities and want to execute your own algorithms, you can do this by packaging your code into a Docker image and uploading it to AWS (specifically, the Elastic Container Registry, or ECR). AWS has multiple examples for doing this in other languages, and can be found here:

https://github.com/awslabs/amazon-sagemaker-examples/tree/master/advanced_functionality


# 2. Preparing your code locally
## MATLAB Executable
My example code here is very simple. The train.m is the "master" file that borrows heavily from the train.py file in the TensorFlow example, and does the following:

  * Read the data in
  * Execute the actual algorithm/important part
  * Write the data
  
Reading and Writing the data needs to be done in specific folders that SageMaker uses, with the structure shown below (which comes from their "Tensorflow Bring Your Own" example):
~~~
/opt/ml
├── input
│   ├── config
│   │   ├── hyperparameters.json
│   │   └── resourceConfig.json
│   └── data
│       └── <channel_name>
│           └── <input data>
├── model
│   └── <model files>
└── output
    └── failure
~~~

The train.m file will thus read in data from /opt/ml/input/data/training/ and write the successful output to /opt/ml/model/. In this example a simple function that squares a number is called from train.m, but it could theoretically be any MATLAB function.

There are at least two different Matlab Runtime Environments that exist: one that includes "all" of MATLAB's functionality and another that has just the "numerics" capability. For my purposes I only needed the numerics, and the only way to get this is to select the "Runtime included in package" option at the top of the compiler window, and then use the installer that includes that runtime in the Docker image (by default it's found in the "for_redistribution" folder and is titled MyAppInstaller_mcr.install).

  
## Build your Docker Image
Dockerfiles have all the instructions for creating an image. The only real Matlab-specific command that occurs in this Dockerfile compared to others is ensuring the MATLAB runtime environment variable is set. Since I'm using R2018b, the folder is /mcr/v95; if you're using a different version you may need to change it to the appropriate one. Besides that, setting the Working Directory to be the location where *train* is located ensures things are executed appropriately.

Assuming you have the Dockerfile in a folder that also has a folder InstallFile/ that has the .install file, you should be able to build the command with:
  
      docker build -t my_image .

Summarizing that all with a screenshot:

![Docker build command](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/docker%20build.JPG)


## Test your Docker Image

On the backend, SageMaker calls your image with something like:
  
    docker run -v /{ml data}:/opt/ml/ my_image train
    
The mount command (-v) establishes a connection between the two directories; anything that is on the host {ml data} folder will be available to the container, and any data that gets written to that folder will be available to the host. A very important aspect of how this works within Docker is that it will overwrite anything you have in the /opt/ml/ folder, so don't put anything in there that you'll need for execution.

The Docker command up above can be useful for local testing. If you'd like to do this, create a folder on your local drive that has the same folder structure as the 'opt/ml' folder, put your input files into the appropriate input folder on your local drive, then execute the Docker command. If your code runs propery it will write the data to the Model folder; if not it will go to the /output/failure. 

# 3. Getting your code on AWS
  ## 3.1 Make the repository on ECR 
  ECR is AWS's Docker image Repository service. When you create a repository, it will have a name you give it, and then a URI which is very important for the subsequent steps. The URI will look something like:
  
    {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}

## 3.2 Upload your image to ECR
Once the repo is created on ECR and the image is created on your local machine, you can push the image up to AWS.

  ### 3.2.1 Tag the image with the repo name you just made
  You need to tag the image with the same name as the repo you just created. Do this by running:
      
      docker tag my_image {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}
  
  ### 3.2.2. Login to AWS through the CLI
  In the terminal, run the following command:
  
      aws ecr get-login --region us-west-1 --no-include-email
  
  This will spit out a huge wall of text that's actually a command that establishes a connection to AWS. Copy that output, paste the output back into the terminal, and run the command.
  
  ### 3.2.3 Upload the image
  With the image tagged and AWS connection made, you can upload the image to ECR by running:
    
    docker push {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}
  
# 4. Prepare S3
S3 is one of AWS's data-storage solutions. This is where our input data lives and where the outputs will get written to. Make a bucket, then a folder inside that bucket that has your input data, similar to the below:

![Image of S3 Bucket](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/s3.JPG)

Additionally, make a folder for your output to be saved to.
  
# 5. Execute your Code
  There are two ways of doing this through SageMaker: through the web interface for initiating Training Jobs, and through SageMaker's Jupyter Notebooks.
  ## 5.1 Role
AWS Manages permissions across their platform through the use of "roles". When you execute a training job on SageMaker with a role, that role needs to have access to the S3 data. You'll have different options depending on what your use case is, as shown below:

![Image of IAM Role with S3 Access](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/iam%20role.JPG)

You can create this role when starting a Training job in the next step. The safest bet is to make a role that only has access to the S3 bucket that has the necessary data.
  
  ## 5.2 Web Interface
Setting up your training job through the web interface is fairly straightforward. On the left hand side under Training, select Training Jobs, then the orange "Create training job" button in the top-right. Give your training job a unique name and select the IAM role that has access to S3. For the Algorithm Source, select "Your own algorithm container in ECR", then provide the link ({aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}). For Input mode select File, and for Instance type I used ml.m4.xlarge.

![SageMaker Web Training 1](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/trainWeb1.JPG)


Since this is a Training job, the Input data configuration should have "training" in the Channel name. I don't know what Record wrapper, S3 data type, or S3 data distribution type are, so I left them at their defaults. S3 location is the location of your data, so make sure to put this in. It should look something like: s3://bucket/path-to-your-input-data/

In the Output data configuration, put the S3 location where you want to write your data, and it should look like: s3://bucket/path-to-your-output-data/

*Note: Make sure you include the / at the end of the output folder. I didn't and S3 wouldn't show my data.*

![SageMaker Web Training 2](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/trainWeb2.JPG)


Finally, select Create training job to kick it off.

  ## 5.3 Jupyter Notebook
  The code below is adapted from other AWS examples. Simply update the image string, output path, and input path. 
  
``` 

import boto3
import re

import os
import numpy as np
import pandas as pd
from sagemaker import get_execution_role

role = get_execution_role()

import sagemaker as sage
from time import gmtime, strftime

sess = sage.Session()

account = sess.boto_session.client('sts').get_caller_identity()['Account']
print(role)
region = sess.boto_session.region_name
image = '{aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}'.format(account, region)
        
matlabHelloWorld = sage.estimator.Estimator(image,
                       role, 1, 'ml.m5.large',
                       output_path="s3://{s3 bucket name}/{s3 output folder}/".format(sess.default_bucket()),
                       sagemaker_session=sess)

print(sess.default_bucket())

matlabHelloWorld.fit("s3://{s3 input data bucket}/")

```

  
# 6. Finding the results
The output of the algorithms are written to the S3 output folder you specify. To get your data, navigate over to the appropriate folder in the S3 bucket you specified when the training job was started.

![S3 Output](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/s3%20output.JPG)


