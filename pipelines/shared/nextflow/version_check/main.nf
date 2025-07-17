nextflow.enable.dsl = 2
include { version_check } from '../workflows/version-check.nf'
workflow { version_check() } 
