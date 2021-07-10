colon := :
$(colon) := :
IMAGE_NAME ?= easi/canal-adapter$(:)v1.1.5-6

build:
	docker build -t $(IMAGE_NAME) .

run:
	docker run -it --name=canal-adapter --rm \
		--env="canal.destinations=cdc" \
		--env="canal.tcp.server.host=host.docker.internal:11111" \
		-v $(CURDIR)/application.yml:/opt/canal-adapter/conf/application.yml \
		$(IMAGE_NAME)

bash:
	docker run -it --rm \
		--env="canal.instance.master.address=prod-delivery-mirror.cluster-czmlu1dglm0q.ap-northeast-1.rds.amazonaws.com:3306" \
		--env="canal.instance.database=easi_delivery" \
		--env="canal.instance.dbUsername=cdc" \
		--env="canal.instance.dbPassword=FOOBAR" \
		--env="canal.destinations=cdc" \
		--env="cdc.mysql.jdbc.username=cdc" \
		--env="cdc.mysql.jdbc.password=test" \
		--env="cdc.mysql.jdbc.database=cdc" \
		-v $(CURDIR)/app.sh:/app.sh \
		$(IMAGE_NAME) bash

push:
	docker push $(IMAGE_NAME)
