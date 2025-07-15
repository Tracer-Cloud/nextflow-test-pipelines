.PHONY: all test_rnaseq_light test_rnaseq_quant_only test_rnaseq_align_count

all: test_rnaseq_light test_rnaseq_quant_only test_rnaseq_align_count

# Run lightweight RNA-seq test pipeline
.PHONY: test_rnaseq_light
test_rnaseq_light:
	@cd test-rnaseq-light && nextflow run main.nf

# Run quantification-only RNA-seq pipeline
.PHONY: test_rnaseq_quant_only
test_rnaseq_quant_only:
	@cd test-rnaseq-quant-only && nextflow run main.nf

# Run alignment + quantification RNA-seq pipeline
.PHONY: test_rnaseq_align_count
test_rnaseq_align_count:
	@cd test-rnaseq-align-count && nextflow run main.nf