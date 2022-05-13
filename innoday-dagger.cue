package main

import (
	"dagger.io/dagger"

	"universe.dagger.io/aws"
	"universe.dagger.io/docker"
	"universe.dagger.io/go"
)

dagger.#Plan & {
	client: {
		filesystem: ".": read: contents: dagger.#FS
		env: {
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
					config: cmd: ["/app/main"]
				},
			]
		}

		authenticate: aws.#Container & {
			always:      true
			credentials: aws.#Credentials & {
				accessKeyId:     client.env.AWS_ACCESS_KEY_ID
				secretAccessKey: client.env.AWS_SECRET_ACCESS_KEY
			}

			command: {
				name: "sh"
				flags: "-c": "aws --region eu-west-1 ecr get-login-password > /output.txt"
			}

			export: files: "/output.txt": _
		}

		push: docker.#Push & {
			image: dockerize.output
			dest:  "666831343496.dkr.ecr.eu-west-1.amazonaws.com/innoday-dagger"
			auth: {
				username: "AWS"
				secret:   core.#NewSecret & {
					input: authenticate.export.files."/output.txt"
				}
			}
		}
	}
}
