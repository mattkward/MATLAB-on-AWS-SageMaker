# MATLAB-on-AWS-SageMaker

This Repo provides an approach for executing MATLAB stand-alone executables on AWS SageMaker. It borrows heavily from AWS's "Bring Your Own Algorithms", which takes the executable and places it within a Docker image. 

Software used:
Ubuntu
MATLAB 20189ab
Compiler Toolbox
Docker
AWS Services (AWS Command Line Interface, SageMaker, S3, ECR, etc.?)

Useful resources include:
<AWS bring your own TensorFlow example>


<Heading> Docker and AWS
For the purpose of this overview, Docker containers are self-contained images that have everything required for executing code, including OS and supporting libraries. Because of this, containers are very portable and can be used for a number of different use cases.
  
  On the backend, AWS does something like:
  docker run -v /{ml data}:/opt/ml/ my_image train

<Heading > MATLAB Executable
The train.m file borrows heavily from the "train.py" file in the TensorFlow example from AWS. 
  
  
  <Heading> Dockerfile
  Dockerfiles have all the instructions for creating an Image.
  Big Things:
  
  
  <Heading> Getting your code on AWS
  <subheading> Generate your executable using the Compiler Toolbox, and put it in the right folder
    -Make sure to include the Runtime in the executable
    
  <subheading> Build your Docker Image
  
  <Subheading> Make the repository on ECR 
  ECR is AWS's Docker image Repository service. 

<subheading> Upload your image to ECR
  -Tag the image with the repo name you just made
  -Login to AWS through the CLI
  -Upload the image
  
  <Heading> Prepare S3
  S3 is one of AWS's data-storage solutions. This is where our input data lives and where the outputs will get written to.
  
  <Heading> Execute your Code
  There are two ways of doing this through SageMaker: Training Jobs through the web interface
