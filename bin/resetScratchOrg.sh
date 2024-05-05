#!/bin/bash
sf org delete scratch --no-prompt --target-org apexdomainbuilder
sf org create scratch --alias apexdomainbuilder --set-default --duration-days 1 --definition-file config/project-scratch-def.json
sf project deploy start --ignore-conflicts 