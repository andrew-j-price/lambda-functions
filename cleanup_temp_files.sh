#!/bin/bash

# ensure this command is only performed for this git repo
check_repo=$(grep lambda-functions.git .git/config &> /dev/null)
return_code=$?

if [ $return_code != 0 ]; then
    echo "NOT IN EXPECTED GIT REPOSITORY"
    echo "AUTOMATED DELETING TOO RISKY"
    echo "EXITING..."
    exit 1
fi

# python related
find . -name ".tox" -type d -exec sudo rm -rf "{}" \;
find . -name ".pytest_cache" -type d -exec sudo rm -rf "{}" \;
find . -name "__pycache__" -type d -exec sudo rm -rf "{}" \;
find . -name "build" -type d -exec sudo rm -rf "{}" \;
find . -name "dist" -type d -exec sudo rm -rf "{}" \;
find . -name ".eggs" -type d -exec sudo rm -rf "{}" \;
find . -name "*.egg-info" -type d -exec sudo rm -rf "{}" \;
find . -name "*.pyc" -type f -exec sudo rm -f "{}" \;

# coverage related
find . -name ".coverage" -type f -exec sudo rm -f "{}" \;
find . -name "coverage.xml" -type f -exec sudo rm -f "{}" \;
find . -name "htmlcov" -type d -exec sudo rm -rf "{}" \;
