SHELL=/bin/bash

GO ?= go
GOVERSION ?= go1.16
BIN ?= bin
IGNORE := $(shell mkdir -p $(BIN))

# used to get the short commit id
GITREF := $(shell git describe --always --long --dirty)
GOBUILD := CGO_ENABLED=0 $(GO) build $(RACE) -ldflags "-X github.com/fdawg4l/tesla-gateway-getter/pkg/build.GitCommitID=$(GITREF)"
.PHONY: all tools clean test check distro \
	goversion goimports gopath govet gofmt golint

.DEFAULT_GOAL := all

ifeq ($(ENABLE_RACE_DETECTOR),true)
	RACE := -race
else
	RACE :=
endif

# utility targets
goversion:
	@echo Checking go version...
	@( $(GO) version | grep -q $(GOVERSION) ) || ( echo "Please install $(GOVERSION) (found: $$($(GO) version))" && exit 1 )

dist: tesla-gateway-getter
all: test dist

tools: $(GOIMPORTS)

goimports: $(GOIMPORTS)
$(GOIMPORTS):
	@echo Building $(GOIMPORTS)...
	@$(GO) get -u golang.org/x/tools/cmd/goimports

govet: goversion $(GOIMPORTS)
	@echo Checking go vet...
	@$(GO) vet -all -lostcancel -tests $$(find . -type d -not -name vendor -not -name bin -not -name .git)
	@echo Checking go imports...
	@$(GOIMPORTS) -local semifreddo -d $$(find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./api/*") 2>&1

tesla-gateway-getter := $(BIN)/tesla-gateway-getter
tesla-gateway-getter : $(tesla-gateway-getter)
$(tesla-gateway-getter):
	@echo Building server ${tesla-gateway-getter}
	$(GOBUILD) -o ${tesla-gateway-getter} ./main.go

clean:
	@echo Removing build output directory $(CURDIR)/bin
	@rm -rf $(CURDIR)/bin

test: dist
	$(GO) test -v ./...

docker: dist
	@docker build -t tesla-gateway-getter .
	@docker save tesla-gateway-getter > tesla-gateway-getter-$(GITREF).tar
