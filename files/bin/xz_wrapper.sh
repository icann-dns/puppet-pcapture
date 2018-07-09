#!/bin/bash
for file in $@ ; do
	/usr/bin/xz -S .tmp_xz -1 ${file} && /bin/mv ${file}.tmp_xz ${file}.xz
done
  
