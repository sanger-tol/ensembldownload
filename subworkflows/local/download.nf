//
// Download all files from Ensembl and prepare clean output channels for post-processing
//

include { ENSEMBL_GENESET_DOWNLOAD } from '../../modules/local/ensembl_geneset_download'
include { ENSEMBL_GENOME_DOWNLOAD  } from '../../modules/local/ensembl_genome_download'


workflow DOWNLOAD {
    take:
    annotation_params // tuple(outdir, assembly_accession, annotation_method, geneset_version)

    main:

    ch_download_params = annotation_params.map { outdir, assembly_accession, annotation_method, geneset_version ->
            def method = annotation_method == "ensembl" ? annotation_method : "ensembl_${annotation_method}"
            tuple(
                // meta
                [
                    id: "${assembly_accession}.${method}.${geneset_version}",
                    assembly_accession: assembly_accession,
                    geneset_version: geneset_version,
                    method: method,
                    outdir: outdir,
                ],

                // ftp_path
                // Turn "GCA_927399515.1" to "GCA/927/399/515/1"
                // e.g. https://ftp.ebi.ac.uk/pub/ensemblorganisms/GCA/905/163/415/1/braker/2022_03
                [
                    params.ftp_root,
                    "GCA",
                    assembly_accession.substring(4, 7),
                    assembly_accession.substring(7, 10),
                    assembly_accession.substring(10, 13),
                    assembly_accession.substring(14),
                    annotation_method,
                    geneset_version,
                ].join("/")
            )
        }


    // 1. Gene annotations

    ENSEMBL_GENESET_DOWNLOAD(
        ch_download_params
    )

    // Set meta.id
    ch_all_gene_fasta = channel.empty()
        .mix(ENSEMBL_GENESET_DOWNLOAD.out.cdna)
        .mix(ENSEMBL_GENESET_DOWNLOAD.out.pep)
        .map { meta, fasta -> tuple(meta + [id: fasta.baseName], fasta) }

    // tuple(meta,gff) at this stage
    ch_gff = ENSEMBL_GENESET_DOWNLOAD.out.gff
        .map { meta, gff -> tuple(meta + [id: gff.baseName], gff) }


    // 2. Repeat masking

    ENSEMBL_GENOME_DOWNLOAD(
        ch_download_params
    )

    ch_genome_fasta = ENSEMBL_GENOME_DOWNLOAD.out.fasta
        .map { meta, fasta -> tuple(meta + [id: "${meta.id}.repeats"], fasta) }


    emit:
    genes  = ch_all_gene_fasta // meta, path: (cdna|cds|pep).fa
    gff    = ch_gff // meta, path: genes.gff
    genome = ch_genome_fasta // meta, path: genome.fa
}
