
FROM ubuntu:bionic

# Make all the file directories that are needed. Some of the things that are pulled at the beginning may be unnecessary.
RUN apt-get -qq update && apt-get -qq install -y \
    unzip \
    xorg \
    wget \
    curl && \
    mkdir /execute && \
    mkdir /opt/program && \
    mkdir /opt/ml && \
    mkdir /opt/ml/input && \
    mkdir /opt/ml/input/config && \
    mkdir /opt/ml/input/data && \
    mkdir /opt/ml/input/data/training && \
    mkdir /opt/ml/input/data/testing && \
    mkdir /opt/ml/input/data/validation && \
    mkdir /opt/ml/model && \
    mkdir /opt/ml/output && \
    mkdir /opt/ml/output/failure && \
    mkdir /opt/ml/code && \
    mkdir /mcr-install && \
    mkdir /mcr && \
    cd /mcr-install

# Copy the contents from the InstallFile folder from the host machine to the /mcr-install folder in the image and install
COPY /InstallFile/ /mcr-install

RUN ./mcr-install/MyAppInstaller_mcr.install -agreeToLicense yes -mode silent -destinationFolder /mcr

# move the application from the default folder over to /opt/program. This can likely be moved somewhere else, 
# but be sure to set the WORKDIR appropriately
RUN cd /mcr/application && \
    mv train /opt/program

# Remove the Install folder from the image since it's no longer needed
RUN rm -rf mcr-install


# Build environment variables
ENV MCR_ROOT=/mcr/v95
ENV PATH=$PATH:${MCR_ROOT}/bin
ENV XAPPLRESDIR=/mcr/v95/X11/app-defaults
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCR_ROOT}/runtime/glnxa64:${MCR_ROOT}/bin/glnxa64:${MCR_ROOT}/sys/os/glnxa64:${MCR_ROOT}/sys/opengl/lib/glnxa64
ENV PATH="/opt/program:${PATH}"

# Set the working directory to where "train" was placed
WORKDIR /opt/program
