VERSION_DEV = 0.1.4_dev
VERSION_PROD = 0.1.6

commit:
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

commit-release-major:
	mix bump_release major
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

commit-release-minor:
	mix bump_release minor
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

commit-release-patch:
	mix bump_release patch
	mix test
	mix format
	mix credo --strict
	git add .
	git cz

dev-release:
	mix deps.get
	mix compile
	mix release

builddockerprod: 
	docker build --tag madclaws/watchex .
	docker tag madclaws/watchex madclaws/watchex:$(VERSION_PROD)

builddockerdev: 
	docker build --file dev.dockerfile --tag madclaws/watchex .
	docker tag madclaws/watchex madclaws/watchex:$(VERSION_DEV)

pushdockerdev: builddockerdev
	docker push madclaws/watchex:$(VERSION_DEV)

pushdockerprod: builddockerprod
	docker push madclaws/watchex:$(VERSION_PROD)

rundockerprod: 
	docker run --name watchex-$(VERSION_PROD) --publish 6968:6968 --detach --env WATCHEX_PORT=6968 --env SECRET_KEY_BASE=${SECRET_KEY_BASE} watchex:$(VERSION_PROD)

rundockerdev: builddockerdev
	docker run --name watchex-$(VERSION_DEV) --publish 4000:4000 --detach --env WATCHEX_PORT=4000 --env SECRET_KEY_BASE=${SECRET_KEY_BASE} watchex:$(VERSION_DEV)