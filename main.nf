#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Parameters
params.input_fastq = null
params.num_splits = 4
params.outdir = "results"
params.help = false

// Help message
def helpMessage() {
    log.info"""
    Usage:
    nextflow run pipeline.nf --input_fastq sample.fastq --num_splits 4 --outdir results

    Required arguments:
    --input_fastq       Path to input FASTQ file
    
    Optional arguments:
    --num_splits        Number of files to split into (default: 4)
    --outdir           Output directory (default: results)
    --help             Show this help message
    """.stripIndent()
}

// Show help message if requested
if (params.help) {
    helpMessage()
    exit 0
}

// Validate required parameters
if (!params.input_fastq) {
    log.error "Please specify an input FASTQ file with --input_fastq"
    exit 1
}

// Process to split FASTQ file using seqkit
process SPLIT_FASTQ {
    tag "Splitting ${fastq_file.baseName}"
    publishDir "${params.outdir}/split_files", mode: 'copy'
    
    input:
    path fastq_file
    val num_splits
    
    output:
    path "${fastq_file}.split/*.part_*.f*q*", emit: split_files
    
    script:
    """
    # Use seqkit split2 to split by number of parts
    seqkit split2 -p ${num_splits} ${fastq_file}
    """
}

// Process to analyze each split file independently
// Replace this with your actual analysis process
process PROCESS_SPLIT {
    tag "Processing ${split_file.baseName}"
    publishDir "${params.outdir}/processed", mode: 'copy'
    
    // Resource requirements (can be overridden in config)
    cpus 4
    memory '16 GB'
    time '2h'
    
    input:
    path split_file
    
    output:
    path "${split_file.baseName}_stats.txt", emit: stats
    path "${split_file.baseName}_processed.fastq", emit: processed_fastq
    
    script:
    """
    # Example processing: count sequences and calculate basic stats
    # Replace this section with your actual processing logic
    
    echo "Processing ${split_file}" > ${split_file.baseName}_stats.txt
    echo "File: ${split_file}" >> ${split_file.baseName}_stats.txt
    echo "CPUs used: ${task.cpus}" >> ${split_file.baseName}_stats.txt
    echo "Memory allocated: ${task.memory}" >> ${split_file.baseName}_stats.txt
    echo "Total lines: \$(wc -l < ${split_file})" >> ${split_file.baseName}_stats.txt
    echo "Total sequences: \$(( \$(wc -l < ${split_file}) / 4 ))" >> ${split_file.baseName}_stats.txt
    echo "Processing started at: \$(date)" >> ${split_file.baseName}_stats.txt
    
    # Example: simple quality filtering using seqkit (more efficient than awk)
    # This is just an example - replace with your actual processing
    # seqkit seq -Q 20 -j ${task.cpus} ${split_file} > ${split_file.baseName}_processed.fastq
    seqkit stats -j ${task.cpus} ${split_file} > ${split_file.baseName}_processed.fastq
    
    echo "Processing completed at: \$(date)" >> ${split_file.baseName}_stats.txt
    echo "Processed sequences: \$(( \$(wc -l < ${split_file.baseName}_processed.fastq) / 4 ))" >> ${split_file.baseName}_stats.txt
    """
}

// Process to combine results (optional)
process COMBINE_RESULTS {
    tag "Combining results"
    publishDir "${params.outdir}/final", mode: 'copy'
    
    input:
    path stats_files
    path processed_fastq_files
    
    output:
    path "combined_stats.txt", emit: combined_stats
    path "combined_processed.fastq", emit: combined_fastq
    
    script:
    """
    # Combine all stats files
    echo "=== Combined Processing Statistics ===" > combined_stats.txt
    echo "Generated at: \$(date)" >> combined_stats.txt
    echo "" >> combined_stats.txt
    
    for stats_file in ${stats_files}; do
        echo "--- \$stats_file ---" >> combined_stats.txt
        cat \$stats_file >> combined_stats.txt
        echo "" >> combined_stats.txt
    done
    
    # Combine all processed FASTQ files
    cat ${processed_fastq_files} > combined_processed.fastq
    
    echo "=== Final Summary ===" >> combined_stats.txt
    echo "Total processed sequences: \$(( \$(wc -l < combined_processed.fastq) / 4 ))" >> combined_stats.txt
    """
}

// Workflow
workflow {
    // Create input channel
    fastq_ch = Channel.fromPath(params.input_fastq, checkIfExists: true)
    
    // Split the FASTQ file
    SPLIT_FASTQ(fastq_ch, params.num_splits)
    
    // Flatten the split files channel so each file is processed independently
    split_files_ch = SPLIT_FASTQ.out.split_files.flatten()
    
    // Process each split file independently
    PROCESS_SPLIT(split_files_ch)
    
    // Collect all results for combining (optional)
    stats_collected = PROCESS_SPLIT.out.stats.collect()
    fastq_collected = PROCESS_SPLIT.out.processed_fastq.collect()
    
    // Combine results
    COMBINE_RESULTS(stats_collected, fastq_collected)
}

workflow.onComplete {
    println "Pipeline completed at: ${new Date()}"
    println "Results saved to: ${params.outdir}"
}
