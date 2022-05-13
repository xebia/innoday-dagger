package main

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/aws"
	"universe.dagger.io/aws/cli"
	"universe.dagger.io/docker"
	"universe.dagger.io/go"
)

dagger.#Plan & {
	client: {
		filesystem: ".": read: contents: dagger.#FS
		env: {
			DOCKER_REPOSITORY:     string | *"666831343496.dkr.ecr.eu-west-1.amazonaws.com/innoday-dagger"
			AWS_ACCESS_KEY_ID:     dagger.#Secret
			AWS_SECRET_ACCESS_KEY: dagger.#Secret
		}
	}

	actions: {
		test: go.#Test & {
			source:  client.filesystem.".".read.contents
			package: "./..."
		}

		build: go.#Build & {
			source: client.filesystem.".".read.contents
		}

		dockerize: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "alpine"
				},
				docker.#Copy & {
					contents: build.output
					dest:     "/app"
				},
				docker.#Set & {
					config: cmd: ["/app/innoday-dagger"]
				},
			]
		}

		authenticate: cli.#Command & {
			credentials: aws.#Credentials & {
				accessKeyId:     client.env.AWS_ACCESS_KEY_ID
				secretAccessKey: client.env.AWS_SECRET_ACCESS_KEY
			}
			options: region: "eu-west-1"
			service: {
				name:    "ecr"
				command: "get-login-password"
			}
		}

		load: core.#NewSecret & {
			input: authenticate.export.rootfs
			path:  "/output.txt"
		}

		push: docker.#Push & {
			image: dockerize.output
			dest:  client.env.DOCKER_REPOSITORY
			auth: {
				username: "AWS"
				secret:   load.output
			}
		}
	}
}
