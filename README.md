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
  https://github.com/awslabs/amazon-sagemaker-examples/tree/master/advanced_functionality/tensorflow_bring_your_own


<Heading> Docker and AWS
For the purpose of this overview, Docker containers are self-contained images that have everything required for executing code, including OS and supporting libraries. Because of this, containers are very portable and can be used for a number of different use cases.
  
  On the backend, AWS does something like:
  docker run -v /{ml data}:/opt/ml/{something} my_image train
  
  The mount command (-v) establishes a connection between the two directories; anything that is on the host {ml data} folder will be available to the container, and any data that gets written to that folder will be available to the host. A very important aspect of how this works within Docker is that it will overwrite anything you have in the /opt/ml/{something} folder, so don't put anything in there that you'll need for execution.

<Heading > MATLAB Executable
My example code here is very simple. The train.m is the "master" file that borrows heavily from the train.py file in the TensorFlow example, and does the following:
  -read the data in
  -execute the actual algorithm/important part
  -write the data


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
  There are two ways of doing this through SageMaker: through the web interface for initiating Training Jobs, and through SageMaker's Jupyter Notebooks.
  <subheading> Web Interface
    
  <subheading> Jupyter Notebook
