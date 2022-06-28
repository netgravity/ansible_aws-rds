#!/bin/bash
aws rds describe-db-engine-versions --engine mysql --engine-version 5.7.36 --query 'DBEngineVersions[*].ValidUpgradeTarget[?IsMajorVersionUpgrade==`false`].EngineVersion' --output=text | awk '{print $(NF)}'
