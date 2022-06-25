#!/bin/bash
aws rds describe-db-engine-versions --engine postgres --engine-version 13.4 --query 'DBEngineVersions[*].ValidUpgradeTarget[?IsMajorVersionUpgrade==`false`].EngineVersion' --output=text | awk '{print $(NF)}'
