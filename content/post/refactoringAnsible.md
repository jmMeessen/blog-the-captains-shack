+++
author = ""
comments = true
date = "2017-03-27"
draft = true
image = "images/refactoring.gif"
menu = ""
share = true
slug = "refactoringTheShack"
tags = ["Ansible", "docker"]
title = "Spring refactoring of the Captain's shack"

+++


The best way to prevent damage due to tampering on an Internet facing server is to rebuild it regularly. The most efficient way is the scripted way. From day one the "Captain's Shack" server has been configured with Ansible so that the server can be regularly re-initialized. 
Each component, defined in an Ansible role, is deployed as a Docker container. To orchestrate these containers, I use a central "docker-compose" file.

![kimsufi](/images/Kimsufi.png)

Initialy, the docker configuration (and the docker-compose) was managed via a single docker-compose file. This design did not allow to disable a service (like Nexus or Lime Survey) by just commenting out the call to the Ansible role. It required adapting several Ansible scripts or configuration file. Very impractible.  

The partical case of needing to disable the "Lime Survey" service made the need  of some refactoring obvious.

The main issue was that enabling/disabling a service requires to change the docker-compose file in different sections.  There is obviously the service section that needs to be updated but also the volume part and, more annoying, the "web" service (Nginx) part. 

I initialy tried to achieve this with the blockinfile Ansible module. It turned out to be clumsy especially to manage properly formated yaml files. It required to start the block with a dummy line that would set the correct offset of the block (as this line was inserted at column 0). That dummy line needed to be removed in the following step. Also annoying was the fact that the module inserted each time a "noisy" comment before and after the inserted block. This made the generated docker-compose file difficult to read for a human reader. Repeadly manipulating individual line in the "web" service part was also very annoying.

So I chose to go for the proverbial plan B.

The idea is to  have several docker-compose.yml that will first be "superposed" before being processed by the docker-compose engine. Each compose file define what is needed to activate a single service. It defines the service and volume part but also the required additional configuraion to the "web" service (reverse proxy).

< sample comes here>

These compose files can be assembled either with the `-f` switch of the docker-compose command line or by setting the COMPOSE_FILE environement variable with list of these files seperated by a ":". I chose the second strategy because it was easier to setup correctly with Ansible.