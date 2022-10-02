NAME := tekton-pipeline
CHART_DIR := charts/${NAME}
# 带 ?号代表可以通过 外部传入 比如 make CHART_VERSION=0.32.0 fetch
CHART_VERSION ?= 0.29.0

CHAR_REPO_NAMESPACE ?= admin
CHART_REPO ?= https://repomanage.rdc.aliyun.com/helm_repositories/${CHAR_REPO_NAMESPACE}

REPO_USERNAME ?= admin
REPO_PASSWORD ?= admin

fetch:
	rm -f ${CHART_DIR}/templates/*.yaml
	mkdir -p ${CHART_DIR}/templates
ifeq ($(CHART_VERSION),latest)
	curl -sS https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml > ${CHART_DIR}/templates/resource.yaml
else
	curl -sS https://storage.googleapis.com/tekton-releases/pipeline/previous/v${CHART_VERSION}/release.yaml > ${CHART_DIR}/templates/resource.yaml
endif
	jx gitops split -d ${CHART_DIR}/templates
	jx gitops rename -d ${CHART_DIR}/templates
	# move content of data: from feature-slags-cm.yaml to featureFlags: in values.yaml
	yq -i '.featureFlags = load("$(CHART_DIR)/templates/feature-flags-cm.yaml").data' $(CHART_DIR)/values.yaml
	yq -i '.data = null' $(CHART_DIR)/templates/feature-flags-cm.yaml
	# move content of data: from config-defaults-cm.yaml to configDefaults: in values.yaml
	yq -i '.configDefaults = load("$(CHART_DIR)/templates/config-defaults-cm.yaml").data' $(CHART_DIR)/values.yaml
	yq -i '.data = null' $(CHART_DIR)/templates/config-defaults-cm.yaml
	# kustomize the resources to include some helm template blocs
	kustomize build ${CHART_DIR} | sed '/helmTemplateRemoveMe/d' > ${CHART_DIR}/templates/resource.yaml
	jx gitops split -d ${CHART_DIR}/templates
	jx gitops rename -d ${CHART_DIR}/templates
	cp src/templates/* ${CHART_DIR}/templates
ifneq ($(CHART_VERSION),latest)
	sed -i "s/^appVersion:.*/appVersion: ${CHART_VERSION}/" ${CHART_DIR}/Chart.yaml
endif

build:
	rm -rf Chart.lock
	helm dependency build ${CHART_DIR}
	helm lint ${CHART_DIR}

install: clean build
	helm install ${NAME} ${CHART_DIR}

upgrade: clean build
	helm upgrade ${NAME} ${CHART_DIR}

delete:
	helm delete --purge ${NAME}

clean:

release: clean
	sed -i -e "s/version:.*/version: ${CHART_VERSION}/" ${CHART_DIR}/Chart.yaml

	helm dependency build ${CHART_DIR}
	helm lint ${CHART_DIR}
	helm package ${CHART_DIR}
	helm repo add ${CHAR_REPO_NAMESPACE} ${CHART_REPO} --username=${REPO_USERNAME} --password=${REPO_PASSWORD}
	helm cm-push ${NAME}-${CHART_VERSION}.tgz ${CHAR_REPO_NAMESPACE}
	rm  ${NAME}-${CHART_VERSION}.tgz

test:
	cd tests && go test -v

test-regen:
	cd tests && export HELM_UNIT_REGENERATE_EXPECTED=true && go test -v


verify:
	jx kube test run
