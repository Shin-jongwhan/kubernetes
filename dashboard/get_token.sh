#!/bin/bash

CMD="kubectl -n kubernetes-dashboard create token admin-user"
echo "+ $CMD"
eval $CMD
