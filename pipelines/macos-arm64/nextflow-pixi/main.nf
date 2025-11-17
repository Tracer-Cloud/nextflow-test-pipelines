nextflow.enable.dsl = 2
include { tool_execution } from '../../shared/nextflow/workflows/tool-execution.nf'
workflow { tool_execution() }
