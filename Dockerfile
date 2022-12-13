#Start a Linux container using any Linux distribution.

FROM ubuntu:20.04

ARG UID
ARG GID
ARG RUNTIME_ENV

### Note, this is pod specific
ARG AGENT_DOWNLOAD=https://na1.dm-us.informaticacloud.com/saas/download/installer/linux64/agent64_install_ng_ext.bin


# Set environment
ENV LOGIN_DOMAIN=dm-us
ENV RUNTIME_NAME=${RUNTIME_ENV}
ENV INFA_HOME=/opt/informatica
ENV INFA_SA_HOME=${INFA_HOME}/secure_agent
ENV AGENT_FILE=agent64_install_ext.bin

# Set the agent locale and timezone. Modify the commands according to the Linux distribution.
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
locales \
curl \
ca-certificates \
jq \
libidn11 \
nmon \
&& rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US.UTF-8


RUN ulimit -n 32768; 
RUN export LC_ALL=C.utf8
RUN ln -s /usr/lib64/libnsl.so.2.0.0 /usr/lib64/libnsl.so.1 

# Copy the login/cleanup scripts from your local machine onto the Docker container.
COPY ../scripts/login-agent.sh /usr/bin
COPY ../scripts/iics-remove-agent.sh /usr/bin
COPY ../scripts/remove_secure_agents.sh /usr/bin

# Create a user on the container for the agent process to use. Change the ownership and permissions of the login scripts so that the agent user can run them.
RUN groupadd -g $GID agent \
&& useradd -ms /bin/bash -l -u $UID -g $GID agent \
&& chown agent:agent /usr/bin/login-agent.sh \
&& chmod a+x /usr/bin/login-agent.sh \
&& chmod a+x /usr/bin/remove_secure_agents.sh \
&& chown agent:agent /usr/bin/iics-remove-agent.sh \
&& chmod a+x /usr/bin/iics-remove-agent.sh
USER agent

WORKDIR ${INFA_HOME}

# Get the latest version of the secure
RUN curl -o ./${AGENT_FILE} -L ${AGENT_DOWNLOAD} && \
    chmod a+x ./${AGENT_FILE} && \
    ./${AGENT_FILE} -i silent -DUSER_INSTALL_DIR=${INFA_SA_HOME} && \
    printf "\nInfaAgent.GroupName=${RUNTIME_ENV}" >> ${INFA_SA_HOME}/apps/agentcore/conf/infaagent.ini \
    && rm ${INFA_HOME}/${AGENT_FILE}

# Copy the entrypoint script onto the Docker container.
COPY ../scripts/entrypoint.sh ${INFA_SA_HOME}/apps/agentcore/


USER root
RUN chown agent:agent ${INFA_SA_HOME}/apps/agentcore/entrypoint.sh && chmod a+x ${INFA_SA_HOME}/apps/agentcore/entrypoint.sh
USER agent

# Change the working directory for the container.
WORKDIR ${INFA_SA_HOME}/apps/agentcore

# Set the environment variable for the JVM that runs the agent process.
ENV JRE_OPTS -Xms64m -Xmx128m

# Run the entrypoint script to start the agent process, log the agent in to your account, register the agent, and keep the agent process running.
CMD [ "./entrypoint.sh" ]
