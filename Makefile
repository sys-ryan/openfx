REGISTRY=10.0.0.180:5000
TAG?=0.1.0


all: build push deploy

proto:
	cd pb; $(MAKE)

build:
	@echo "#### Compiling OpenFx ####"
	@go build .

push:
	docker build -t ${REGISTRY}/fxgateway:$(TAG) .
	docker push ${REGISTRY}/fxgateway:$(TAG)

deploy:
	@echo "#### Deploying OpenFx to kubernetes cluster ####"
	@kubectl delete --ignore-not-found=true -f ./deploy/yaml/gateway-dep.yml -f ./deploy/yaml/gateway-svc.yml || true
# wait for delete
	@while [ $$(kubectl get pods -n openfx -l "app=fxgateway" -o custom-columns=name:metadata.name,status:status.phase | tail -n+2 | grep Running | wc -l) -ne 0 ]; do echo -n .; sleep 1; done
	@echo 
	@kubectl apply -f ./deploy/yaml/gateway-dep.yml -f ./deploy/yaml/gateway-svc.yml || true
# wait for running
	@while [ $$(kubectl get pods -n openfx -l "app=fxgateway" -o custom-columns=name:metadata.name,status:status.phase | tail -n+2 | grep Running | wc -l) -ne 1 ]; do echo -n .; sleep 1; done
	@echo 
	@kubectl logs -n openfx $$(kubectl get pods --all-namespaces -l app=fxgateway -o name)

git:
	git add .
	git commit -m "$m"
	git push origin master

clean:
	rm -fr ./openfx-gateway

.PHONY: all build push deploy clean
