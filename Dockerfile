FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
MAINTAINER rmz@telenordigital.com


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
##  Setting up the Julia environment by pre-loading
##  pacakges we'll need for GPU-intense Flux.jl workloads.
##
# TODO: Rewrite this to use a utility script that gets a list of packages as
#       parameters.
RUN julia --eval 'import Pkg; Pkg.add("Flux");           Pkg.build("Flux")'
RUN julia --eval 'import Pkg; Pkg.add("CuArrays");       Pkg.build("CuArrays")'
RUN julia --eval 'import Pkg; Pkg.add("CUDAdrv");        Pkg.build("CUDAdrv")'
RUN julia --eval 'import Pkg; Pkg.add("GPUArrays");      Pkg.build("GPUArrays")'


##
## Be able to serve in jupyter notebooks
##

RUN julia --eval 'import Pkg; Pkg.add("IJulia");         Pkg.build("IJulia")'


##
##  ... and be able to do a number of nice things out of the box in general
##
RUN julia --eval 'import Pkg; Pkg.add("FileIO");         Pkg.build("FileIO")'
RUN julia --eval 'import Pkg; Pkg.add("Colors");         Pkg.build("Colors")'
RUN julia --eval 'import Pkg; Pkg.add("BenchmarkTools"); Pkg.build("BenchmarkTools")'
RUN julia --eval 'import Pkg; Pkg.add("ImageShow");      Pkg.build("ImageShow")'
RUN julia --eval 'import Pkg; Pkg.add("Plots");          Pkg.build("Plots")'
RUN julia --eval 'import Pkg; Pkg.add("Images");         Pkg.build("Images")'
RUN julia --eval 'import Pkg; Pkg.add("CSV");            Pkg.build("CSV")'
RUN julia --eval 'import Pkg; Pkg.add("IndexedTables");  Pkg.build("IndexedTables")'
RUN julia --eval 'import Pkg; Pkg.add("Pandas");         Pkg.build("Pandas")'
RUN julia --eval 'import Pkg; Pkg.add("BSON");           Pkg.build("BSON")'


RUN julia --eval 'import Pkg; Pkg.resolve()'

WORKDIR /chezjulia


# TODO Loading chezjulia as a package would make the load-time lower, consider tht for the future.
COPY chez.jl /chezjulia
COPY gameplay.jl /chezjulia
COPY movement.jl /chezjulia
COPY plot_tournament.jl /chezjulia
COPY tests.jl /chezjulia
COPY chessboard.jl /chezjulia
COPY learning_logging.jl /chezjulia
COPY pieces.jl /chezjulia
COPY qlearn.jl /chezjulia

RUN julia --eval 'include("chez.jl")'

WORKDIR /data




#  Run a learning task
CMD julia --eval 'if !isdir("/data"); println("No data bailing out"); exit(); else cd("/chezjulia");include("chez.jl"); cd("/data");  learning_increment(); end'



# Run echo 'alias jupy="jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root"' > /.bashrc

# To run a jupyter notebook, run this command in the shell
# jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root

# To run in docker with GPU support:
#  docker run --gpus all -v /storageHD/userHome/rmz/git:/git -p 127.0.0.1:8888:8888  -it  4cc9da4ac4bf /bin/bash


# docker run --gpus all -v /storageHD/userHome/rmz/git:/git -p 127.0.0.1:8888:8888  -it  a7501342e563 jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root



