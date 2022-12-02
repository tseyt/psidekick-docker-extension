FROM ubuntu:20.04

# Prettify terminal, git completion
ENV SHELL /bin/bash
SHELL ["/bin/bash", "-c"]
RUN echo $'\n\
parse_git_branch() {\n\
  git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \\(.*\\)/ (\\1)/"\n\
} \n\
export PS1="\u@\h \W\[\\033[32m\\]\\$(parse_git_branch)\\[\\033[00m\\] $ "\n\
if [ -f ~/.git-completion.bash ]; then\n\
  . ~/.git-completion.bash\n\
fi\n\
 \n\
alias ll="ls -alF"\n\
alias ls="ls --color=auto"\n\
' >> /root/.bashrc

RUN mkdir -p \
    /root/deps \
    /root/psinode

# Install deps
RUN export DEBIAN_FRONTEND=noninteractive   \
    && apt-get update                       \
    && apt-get install -yq                  \
        curl                                \
        wget                                \
    && apt-get clean -yq                    \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/deps

# Psidk
RUN wget https://github.com/gofractally/psibase/releases/download/rolling-release/psidk-linux.tar.gz \
    && tar xf psidk-linux.tar.gz         \
    && rm psidk-linux.tar.gz
ENV PSIDK_PREFIX=/root/deps/psidk
ENV PATH=$PSIDK_PREFIX/bin:$PATH

# Install deps
RUN export DEBIAN_FRONTEND=noninteractive    \
    && apt-get update                        \
    && apt-get install -yq                   \
        supervisor                           \
    && apt-get clean -yq                     \
    && rm -rf /var/lib/apt/lists/*

# Configure supervisor with psinode
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-psinode-wait /root/psinode/start-psinode-wait

# Add some tools
ADD scripts /root/psinode/scripts
ENV PATH=/root/psinode/scripts:$PATH

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
