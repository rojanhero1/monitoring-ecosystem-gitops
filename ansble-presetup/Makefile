SHELL := /bin/bash

.DEFAULT_GOAL := help

ssh-ping-fast:
        ANSIBLE_STDOUT_CALLBACK=default ansible all -m ping | grep -E "=>" | cut -d '=' -f1

ssh-ping-detailed:
        ANSIBLE_STDOUT_CALLBACK=default ansible all -m setup -a "filter=ansible_hostname" | grep -E "=>|hostname" | cut -d '=' -f1