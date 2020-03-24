# Leanheat connector tests

## System requirements

- Python 3.6.x
- [Poetry](https://python-poetry.org/docs/)

## Installation

Install RobotFramework and dependencies:

    poetry install

## Usage

Set environment variables depending what `Data Product` you are going to be testing. E.g:

    export POT_ACCESS_TOKEN_APP1=...
    export CLIENT_SECRET_WORLD=...
    export PRODUCT_CODE=...

Start test suite:

    poetry run python -m robot -A robotargs.txt connector_tests.robot

Results can be found in `result` folder.
