REPO := rmz/chezjulia

DATADIR := $(shell pwd)/data


# TODO: This should be calculated by  checkingif the running host has
#       any GPUs or not.
# GPUS := --gpus all
GPUS :=

CPUS := --cpus="6"

MOUNTPOINTS :=  -v ${DATADIR}:/mnt/data


clean:
	# This reflect unclean management of temporary files
	rm -f learning_round.txt
	rm -f learning_round_log.csv
	touch learning_round_log.csv
	rm -f *.bson
	# This represents emacs droppings
	find . -name '*~' -exec rm -f {} \;



test:	clean
	julia --eval 'include("src/Chez.jl"); Chez.learning_increment(false)'


long-test:
	julia --eval 'include("src/Chez.jl"); Chez.learning_increment(true)'


#
#  None of the docker stuff seems to be working very well
#
#


package:
	docker build -f Dockerfile -t ${REPO} .

run:
	 docker run ${GPUS} ${CPUS}  ${MOUNTPOINTS}  -it ${REPO}:latest

run-detach:
	 docker run ${GPUS}   ${CPUS}  ${MOUNTPOINTS}  -d  ${REPO}:latest

jupyter:
	docker run ${GPUS}  ${CPUS}  ${MOUNTPOINTS} -p 127.0.0.1:8888:8888  -it ${REPO}:latest jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root
