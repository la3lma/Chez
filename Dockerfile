FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
MAINTAINER rmz@telenordigital.com

##
##TODO
##
#  Maybe consider using this instead? https://hub.docker.com/_/julia

##
## Setting up the linux/julia environent to be able to
## do some basic things
##
RUN apt-get update &&  apt-get install -y wget netcat
RUN cd tmp && wget https://julialang-s3.julialang.org/bin/linux/x64/1.4/julia-1.4.0-linux-x86_64.tar.gz && tar xvzf julia-1.4.0-linux-x86_64.tar.gz
RUN rm /tmp/julia-1.4.0-linux-x86_64.tar.gz
RUN mv /tmp/julia-1.4.0 /usr/local
RUN ln -s /usr/local/julia-1.4.0 /usr/local/julia
RUN echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/julia/bin"' > /etc/environment
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/julia/bin"


##
## Setting up a jupyter environment
##
RUN apt-get install -y build-essential python3.6 python3-pip python3-dev
RUN pip3 install jupyter
RUN pip3 install numpy
RUN pip3 install pandas
EXPOSE 8888


##
##  We'll try to confine ourselves to this directory (mostly)
##
WORKDIR /chezjulia/Chez
RUN julia --eval 'import Pkg; cd("/chezjulia/Chez"); Pkg.activate("."); Pkg.precompile(); Pkg.instantiate()'
# RUN julia --eval 'import Pkg; Pkg.dev("Chez"); using Chez'


# Perhaps Pkg.add("https://github.com/la3lma/chezjulia/Chez") ? 
WORKDIR /data

#  Run a learning task
CMD julia --eval 'if !isdir("/data"); println("No data bailing out"); exit(); else cd("/data"); learning_increment(true); end'
# or 


# Run echo 'alias jupy="jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root"' > /.bashrc

# To run a jupyter notebook, run this command in the shell
# jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root

# To run in docker with GPU support:
#  docker run --gpus all -v /storageHD/userHome/rmz/git:/git -p 127.0.0.1:8888:8888  -it  4cc9da4ac4bf /bin/bash


# docker run --gpus all -v /storageHD/userHome/rmz/git:/git -p 127.0.0.1:8888:8888  -it  a7501342e563 jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root



