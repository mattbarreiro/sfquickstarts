# FROM node:14-bullseye
FROM node:14-buster

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Install Go
ENV GO_VERSION=1.22.4
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz


# ENV PATH="/usr/local/go/bin:/home/node/go/bin:${PATH}"
# ENV PATH="/usr/local/go/bin:${HOME}/go/bin:${PATH}"

# Install prereqs
RUN npm install -g gulp-cli

# Add Golang to path for user `node`
USER node
# RUN echo $PATH > /home/node/path_pre.txt
ENV PATH="/usr/local/go/bin:/home/node/go/bin:${PATH}"
# RUN echo $PATH > /home/node/path_post.txt

# Install CLAAT
RUN go install github.com/googlecodelabs/tools/claat@latest

# USER node

# RUN /usr/local/go/bin/go install github.com/googlecodelabs/tools/claat@latest

# node@83fdf648896c:/workspaces/sfquickstarts_clean/site$ echo $PATH
# /vscode/vscode-server/bin/linux-x64/488a1f239235055e34e673291fb8d8c810886f81/bin/remote-cli:/usr/local/go/bin:/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/node/.vscode-server/data/User/globalStorage/github.copilot-chat/debugCommand