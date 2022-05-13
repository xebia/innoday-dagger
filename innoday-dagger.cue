package main

import (
    "dagger.io/dagger"

    "universe.dagger.io/docker"
    "universe.dagger.io/go"
)

dagger.#Plan & {
    client: filesystem: ".": read: contents: dagger.#FS

    actions: {
        test: go.#Test & {
            source:  client.filesystem.".".read.contents
            package: "./..."
        }

        build: go.#Build & {
            source: client.filesystem.".".read.contents
            package: "main"
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
    }
}