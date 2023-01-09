# GHES / GHEC LFS Auditor

The following Go application is used to audit repositories containing LFS files.

## Prerequisites

You will need Go 1.17 or later installed on your machine. You can download the installer for Go [here](https://go.dev/dl/).

## Building the application

To build the application, run the following command:

```bash
go build .
```

## Usage

To run an audit against repositories within a GHEC organization, run the following:

```bash
./LFSAudit --org-name=<org> --pat-token=<pat-token>
```

To run an audit against repositories within a GHES organization, run the following:

```bash
./LFSAudit --org-name=<org> --pat-token=<pat-token> --is-enterprise-server=<true or false> --enterprise-server-url=<serverbaseurl/api/v3>
```

## Notes

> This script checks for any repositories containing .gitattributes files. While most repos with LFS contain this file, not all of them will have LFS enabled. It's a good starting point though
