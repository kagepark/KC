ps -p $$ | awk '{if($NF != "CMD") print $NF}'
