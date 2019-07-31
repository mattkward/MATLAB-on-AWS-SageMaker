# MATLAB-on-AWS-SageMaker

This Repo provides an approach for executing MATLAB stand-alone executables on AWS SageMaker. It borrows heavily from AWS's "Bring Your Own Algorithms", which takes the executable and places it within a Docker image. 

Software used:
* Ubuntu
* MATLAB 2018b
* Compiler Toolbox
* Docker
* AWS Services (AWS Command Line Interface, SageMaker, S3, ECR, etc.?)



# SageMaker and Docker
SageMaker is AWS's Machine Learning platform and uses Jupyter Notebooks and Python. SageMaker has a few different ways of executing code, including Training Jobs and Inferences/Hosting. This guide is covering Training Jobs only but it's likely the code can be altered for Inference and Hosting. Additionally, this is assuming SageMaker's "File" input is used as opposed to "Pipe".

If you don't want to use SageMaker's built-in capabilities and want to execute your own algorithms, you can do this by packaging your code into a Docker image and uploading it to AWS (specifically, the Elastic Container Registry, or ECR). AWS has multiple examples for doing this in other languages, and can be found here:

https://github.com/awslabs/amazon-sagemaker-examples/tree/master/advanced_functionality

SageMaker makes data available to the running container in the folder structure shown below (which comes from their "Tensorflow Bring Your Own" example):

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

# Preparing your code locally
## MATLAB Executable
My example code here is very simple. The train.m is the "master" file that borrows heavily from the train.py file in the TensorFlow example, and does the following:

  * Read the data in
  * Execute the actual algorithm/important part
  * Write the data

There are at least two different Matlab Runtime Environments that exist: one that includes "all" of MATLAB's functionality and another that has just the "numerics" capability. For my purposes I only needed the numerics, and the only way to get this is to select the "Runtime included in package" option at the top of the compiler window, and then use the installer that includes that runtime in the Docker image (by default it's found in the "for_redistribution" folder and is titled MyAppInstaller_mcr.install).

The train.m here calls a very simple function that squares a number, but it could theoretically be any MATLAB function.
 
  
## Build your Docker Image
   ### Generate your executable using the Compiler Toolbox, and put it in the right folder
  Make sure to include the Runtime in the executable
  
  Dockerfiles have all the instructions for creating an Image. The "big" things this Dockerfile needs to do include:
  * Set MATLAB environment variable
  * Make the working directory the same as where you copy your executable
  
  

 
    
  ### Build your Docker Image
  Make a folder that will have your Dockerfile and install files
  Something like:
  
      docker build -t image_name .

## Test your Docker Image

On the backend, SageMaker calls your image with something like:
  
    docker run -v /{ml data}:/opt/ml/ my_image train
    
The mount command (-v) establishes a connection between the two directories; anything that is on the host {ml data} folder will be available to the container, and any data that gets written to that folder will be available to the host. A very important aspect of how this works within Docker is that it will overwrite anything you have in the /opt/ml/ folder, so don't put anything in there that you'll need for execution.

The Docker command up above can be useful for local testing. If you'd like to do this, create a folder on your local drive that has the same folder structure as the 'opt/ml' folder, put your input files into the appropriate input folder on your local drive, then execute the Docker command. If your code runs propery it will write the data to the Model folder; if not it will go to the /output/failure. 

# Getting your code on AWS
  ## Make the repository on ECR 
  ECR is AWS's Docker image Repository service. When you create a repository, it will have a name you give it, and then a URI which is very important for the subsequent steps. The URI will look something like:
  
    {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}

## Upload your image to ECR
Once the repo is created on ECR and the image is created on your local machine, you can push the image up to AWS.

  ### Tag the image with the repo name you just made
  You need to tag the image with the same name as the repo you just created. Do this by running:
      
      docker tag image_name {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}
  
  ### Login to AWS through the CLI
  In the terminal, run the following command:
  
      aws ecr get-login --region us-west-1 --no-include-email
  
  This will spit out a huge wall of text that's actually a command that establishes a connection to AWS. Copy that output, paste the output back into the terminal, and run the command.
  
  ### Upload the image
  With the image tagged and AWS connection made, you can upload the image to ECR by running:
    
    docker push {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}
  
  # Prepare S3
S3 is one of AWS's data-storage solutions. This is where our input data lives and where the outputs will get written to. 
  
  # Execute your Code
  There are two ways of doing this through SageMaker: through the web interface for initiating Training Jobs, and through SageMaker's Jupyter Notebooks.
  ## Role
AWS Manages permissions across their platform through the use of "roles". When you execute a training job on SageMaker with a role, that role needs to have access to the S3 data. You'll have different options depending on what your use case is, as shown below:

![Image of IAM Role with S3 Access](https://github.com/mattkward/MATLAB-on-AWS-SageMaker/blob/master/screenshots/iam%20role.JPG)

You can create this role when starting a Training job in the next step.
  
  ## Web Interface
Setting up your training job through the web interface is fairly straightforward. On the left hand side under Training, select Training Jobs, then the orange "Create training job" button in the top-right. Give your training job a unique name and select the IAM role that has access to S3. For the Algorithm Source, select "Your own algorithm container in ECR", then provide the link ({aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}). For Input mode select File, and for Instance type I used ml.m4.xlarge.

Since this is a Training job, the Input data configuration should have "train" populated with "train" in the Channel name. I don't know what Record wrapper, S3 data type, or S3 data distribution type are, so I left them at their defaults. S3 location is the location of your data, so make sure to put this in. It should look something like: s3://bucket/path-to-your-input-data/

In the Output data configuration, put the S3 location where you want to write your data, and it should look like: s3://bucket/path-to-your-output-data/
Note: Make sure you include the / at the end of the output folder. I didn't and S3 wouldn't show my data.

Finally, select Create training job to kick it off.

  ## Jupyter Notebook
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

  
  # Finding the results
The output of the algorithms are written to the S3 output folder you specify. To get your data, navigate over to the appropriate folder in the S3 bucket you specified when the training job was started.

