# MATLAB-on-AWS-SageMaker

This Repo provides an approach for executing MATLAB stand-alone executables on AWS SageMaker. It borrows heavily from AWS's "Bring Your Own Algorithms", which takes the executable and places it within a Docker image. 

Software used:
* Ubuntu
* MATLAB 20189ab
* Compiler Toolbox
* Docker
* AWS Services (AWS Command Line Interface, SageMaker, S3, ECR, etc.?)

Useful resources include:
<AWS bring your own TensorFlow example>
  https://github.com/awslabs/amazon-sagemaker-examples/tree/master/advanced_functionality/tensorflow_bring_your_own


# Docker and AWS
For the purpose of this overview, Docker containers are self-contained images that have everything required for executing code, including OS and supporting libraries. Because of this, containers are very portable and can be used for a number of different use cases.
  
  On the backend, AWS does something like:
  
    docker run -v /{ml data}:/opt/ml/{something} my_image train
    
  
  The mount command (-v) establishes a connection between the two directories; anything that is on the host {ml data} folder will be available to the container, and any data that gets written to that folder will be available to the host. A very important aspect of how this works within Docker is that it will overwrite anything you have in the /opt/ml/{something} folder, so don't put anything in there that you'll need for execution.

# MATLAB Executable
My example code here is very simple. The train.m is the "master" file that borrows heavily from the train.py file in the TensorFlow example, and does the following:
  * -read the data in
  * -execute the actual algorithm/important part
  * -write the data
There are at least two different Matlab Runtime Environments that exist: one that includes "all" of Matlab's functionality and another that has just the "numerics" capability. For my purposes I only needed the numerics, and the only way to get this is to select the "Runtime included in package" option at the top of the compiler window, and then use the installer that includes that runtime in the Docker image (by default it's found in the "for_redistribution" folder and is titled MyAppInstaller_mcr.install).
 
  
  # Dockerfile
  Dockerfiles have all the instructions for creating an Image.
  Big Things:
 -Set MATLAB environment variable
 -Make the working directory the same as where you copy your executable
  
  
# Getting your code on AWS
  ## Generate your executable using the Compiler Toolbox, and put it in the right folder
  Make sure to include the Runtime in the executable
    
  ## Build your Docker Image
  Make a folder that will have your Dockerfile and install files
  
  ## Make the repository on ECR 
  ECR is AWS's Docker image Repository service. Log in to the service and create a repo; it should have a name like:
  
    {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/<repo name>

## Upload your image to ECR
  -Tag the image with the repo name you just made
  You need to tag the image with the same name as the repo you just created. Do this by running:
      
      docker tag {image_name} {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}
  
  ### Login to AWS through the CLI
  Run:
      aws ecr get-login --region us-west-1 --no-include-email
  This will spit out a huge wall of text that's actually a command that establishes a connection to AWS. Copy that output, paste the output back into the terminal, and run the command.
  
  ### Upload the image
  With the image tagged and AWS connection made, you can upload the image to ECR by running:
    
    docker push {aws ID number}.dkr.ecr.us-west-1.amazonaws.com/{repo name}
  
  # Prepare S3
  S3 is one of AWS's data-storage solutions. This is where our input data lives and where the outputs will get written to. 
  
  # Execute your Code
  There are two ways of doing this through SageMaker: through the web interface for initiating Training Jobs, and through SageMaker's Jupyter Notebooks.
  <subheading> Role
    AWS Manages permissions across their platform through the use of "roles". When you execute a training job on SageMaker with a role, that role needs to have access to the S3 data. 
  
  ## Web Interface
    
  ## Jupyter Notebook
  
  # Finding the results
  The output of the algorithms are written to the S3 output folder you specify. To get your data, navigate over to the appropriate folder in the S3 bucket you specified when the training job was started.
