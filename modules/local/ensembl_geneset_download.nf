// Module that downloads all necessary geneset files from Ensembl.
// The module checks that the MD5 checksums match before releasing the data.
process ENSEMBL_GENESET_DOWNLOAD {
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::rsync=3.4.1"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/db/dbfb90af7b92fb651e63ab29ef1919606f5fc536a8eaf13da74439bf200dd89e/data'
        : 'community.wave.seqera.io/library/rsync:3.4.1--a8163606c0035a88' }"

    input:
    tuple val(meta), val(ftp_path)

    output:
    tuple val(meta), path("*.cdna.fa.*"), emit: cdna
    tuple val(meta), path("*.genes.gff3.*"), emit: gff
    tuple val(meta), path("*.pep.fa.*"), emit: pep
    tuple val(meta), path("*.xref.tsv.*"), emit: xref
    tuple val("${task.process}"), val('rsync'), eval("rsync --version | sed '1!d;s/^rsync  version //; s/ .*//'"), topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    rsync -av \
      --exclude='*/' \
      --include='pep.fa.bgz*' \
      --include='genes.gff3.bgz*' \
      --include='cdna.fa.bgz*' \
      --include='xref.tsv*' \
      --include='md5sum.txt' \
      --exclude='*' \
      ${ftp_path}/geneset/ ./

    # Some files may be missing from md5sum.txt, let's not bother
    if grep "^\\(cdna\\.fa\\.bgz\\|genes\\.gff3\\.bgz\\|pep\\.fa\\.bgz\\|xref\\.tsv\\)" md5sum.txt > md5checksums_restricted.txt
    then
        md5sum -c md5checksums_restricted.txt
    fi

    for i in pep.fa.* genes.gff3.* cdna.fa.*
    do
        mv \${i} ${prefix}.\${i/.bgz/.gz}
    done
    mv xref.tsv.gz ${prefix}.xref.tsv.gz
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.cdna.fa.gz
    touch ${prefix}.cdna.fa.gz.fai
    touch ${prefix}.cdna.fa.gz.gzi
    touch ${prefix}.genes.gff3.gz
    touch ${prefix}.genes.gff3.gz.csi
    touch ${prefix}.pep.fa.gz
    touch ${prefix}.pep.fa.gz.fai
    touch ${prefix}.pep.fa.gz.gzi
    touch ${prefix}.xref.tsv.gz
    """
}
