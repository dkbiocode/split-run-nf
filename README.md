Split a fastq file, run a user-provided script in bin/, and join output.

This pipeline is built around the task of splitting fastq files for parallel processing, as some tools (such as trf) do not natively support parallelization. 
However, many tasks can be distributed into different processes by dividing the source data. This pipeline accomplishes that.
