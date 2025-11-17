#!/usr/bin/env nextflow

nextflow.enable.dsl = 2
include { tool_execution } from './workflows/tool-execution.nf'

workflow {
    tool_execution()
}
