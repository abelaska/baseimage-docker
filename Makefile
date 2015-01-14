NAME = loysoftware/baseimage
REPO = docker.loysoft.com
VERSION = 0.9.9

.PHONY: all build test tag_latest release ssh

all: build

build:
	docker build -t $(NAME):$(VERSION) --rm image

test:
	env NAME=$(NAME) VERSION=$(VERSION) ./test/runner.sh

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest
	docker tag -f $(NAME):latest $(REPO)/$(NAME):latest

squash:
	@ID=$$(docker images $(NAME) | grep -F $(VERSION) | awk '{ print $$3 }') && \
	docker save $$ID | sudo ./bin/docker-squash -verbose -from root -t "$(NAME):squash" | docker load
	docker tag -f $(NAME):squash $(REPO)/$(NAME):squash
	docker push $(REPO)/$(NAME):squash

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(REPO)/$(NAME):latest
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

ssh:
	chmod 600 image/insecure_key.pub
	@ID=$$(docker ps | grep -F "$(NAME):$(VERSION)" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container is not running."; exit 1; fi && \
		IP=$$(docker inspect $$ID | grep IPAddr | sed 's/.*: "//; s/".*//') && \
		echo "SSHing into $$IP" && \
		ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i image/insecure_key root@$$IP
