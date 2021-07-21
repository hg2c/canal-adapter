colon := :
$(colon) := :
IMAGE_NAME ?= easi/canal-adapter$(:)v1.1.5-33

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
		--env="CDC_INSTANCE=cdc" \
		--env="CDC_MASTER_ADDRESS=prod.rds.amazonaws.com:3306" \
		--env="CDC_MASTER_URL=jdbc:mysql:aurora://prod.rds.amazonaws.com:3306?useUnicode=true&characterEncoding=utf-8&enabledTLSProtocols=TLSv1.2" \
		--env="CDC_MASTER_DATABASE=easi_delivery" \
		--env="CDC_MASTER_USERNAME=cdcuser" \
		--env="CDC_MASTER_PASSWORD=cdcpass" \
		--env="CDC_INSTANCE_FILTER_REGEX=easi_delivery\\\\..*" \
		--env="CDC_MASTER_JOURNAL_NAME=mysql-bin-changelog.000061" \
		--env="CDC_MASTER_JOURNAL_POSITION=4771748" \
		--env="CDC_SLAVE_URL=jdbc:cdc" \
		--env="CDC_SLAVE_DATABASE=easi_delivery" \
		--env="CDC_SLAVE_USERNAME=cdcuser" \
		--env="CDC_SLAVE_PASSWORD=cdcpass" \
		-v $(CURDIR)/app.sh:/app.sh \
		$(IMAGE_NAME) bash

push:
	docker push $(IMAGE_NAME)
