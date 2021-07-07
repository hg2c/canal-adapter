colon := :
$(colon) := :
IMAGE_NAME ?= hg2c/canal-adapter$(:)v1.1.5-3

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
		--env="canal.destinations=cdc" \
		--env="cdc.mysql.jdbc.url=jdbc:mysql://hg2c.rds.amazonaws.com:3306/?useUnicode=true&characterEncoding=utf-8&enabledTLSProtocols=TLSv1.2" \
		--env="cdc.mysql.jdbc.username=cdc" \
		--env="cdc.mysql.jdbc.password=test" \
		--env="cdc.mysql.jdbc.database=cdc" \
		-v $(CURDIR)/app.sh:/app.sh \
		$(IMAGE_NAME) bash

push:
	docker push $(IMAGE_NAME)
