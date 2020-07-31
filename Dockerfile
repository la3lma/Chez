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
RUN cd tmp && wget https://julialang-s3.julialang.org/bin/linux/x64/1.4/julia-1.4.2-linux-x86_64.tar.gz && tar xvzf julia-1.4.2-linux-x86_64.tar.gz
RUN rm /tmp/julia-1.4.2-linux-x86_64.tar.gz
RUN mv /tmp/julia-1.4.2 /usr/local
RUN ln -s /usr/local/julia-1.4.2 /usr/local/julia
RUN echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/julia/bin"' > /etc/environment
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/julia/bin"


##
## Setting up a jupyter environment
##
# RUN apt-get install -y build-essential python3.6 python3-pip python3-dev
# RUN pip3 install jupyter
# RUN pip3 install numpy
# RUN pip3 install pandas
# RUN julia --eval 'import Pkg; Pkg.build("IJulia")'
# EXPOSE 8888


##
## Preload chez package into julia
##
##    (This is proper yak-shaving, I'm convinced there must be an easier way.
##     to pre-load a package into julia.)
##

WORKDIR /Chez


RUN julia --eval 'using Pkg; Pkg.add("Flux")'
RUN julia --eval 'using Pkg; Pkg.add("Test")'
RUN julia --eval 'using Pkg; Pkg.add("BSON")'
RUN julia --eval 'using Pkg; Pkg.add("CSV")'
RUN julia --eval 'using Pkg; Pkg.add("DataFrames")'
RUN julia --eval 'using Pkg; Pkg.add("IndexedTables")'
RUN julia --eval 'using Pkg; Pkg.add("Plots")'
RUN julia --eval 'using Pkg; Pkg.add("Printf")'
RUN julia --eval 'using Pkg; Pkg.add("Printf")'
RUN julia --eval 'using Flux, Test, BSON, CSV, DataFrames, IndexedTables, Plots, Printf, Pkg; Pkg.build()'


RUN apt-get install -y git
RUN pwd && git init .
RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"


COPY Project.toml  /Chez
COPY src/          /Chez/src/


RUN git add * && git commit -a -m "initial commit"
RUN julia --eval 'using Pkg; Pkg.add(PackageSpec(path="/Chez"))'
RUN julia --eval 'import Pkg; Pkg.build("Chez"); using Chez'

WORKDIR /data

#  Run a learning task
CMD julia --eval 'if !isdir("/mnt/data"); println("No data bailing out"); exit(); else cd("/mnt/data"); using Chez; Chez.learning_increment(false); end'
