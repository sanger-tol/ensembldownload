//
// Download all files from Ensembl and prepare clean output channels for post-processing
//

include { ENSEMBL_GENESET_DOWNLOAD } from '../../modules/local/ensembl_geneset_download'
include { ENSEMBL_GENOME_DOWNLOAD  } from '../../modules/local/ensembl_genome_download'


workflow DOWNLOAD {
    take:
    annotation_params // tuple(outdir, assembly_accession, annotation_method, geneset_version)

    main:

    // 1. Gene annotations

    ENSEMBL_GENESET_DOWNLOAD(
        annotation_params.map { outdir, assembly_accession, annotation_method, geneset_version ->
            [
                // meta
                [
                    assembly_accession: assembly_accession,
                    geneset_version: geneset_version,
                    method: annotation_method,
                    outdir: outdir,
                ],

                // ftp_path
                // Turn "GCA_927399515.1" to "GCA/927/399/515/1"
                // e.g. https://ftp.ebi.ac.uk/pub/ensemblorganisms/GCA/905/163/415/1/braker/2022_03/geneset/cdna.fa.bgz
                [
                    params.ftp_root,
                    "GCA",
                    assembly_accession.substring(4, 7),
                    assembly_accession.substring(7, 10),
                    assembly_accession.substring(10, 13),
                    assembly_accession.substring(14),
                    annotation_method,
                    geneset_version,
                    "geneset",
                ].join("/")
            ]
        }
    )

    // Set meta.id
    ch_all_gene_fasta = channel.empty()
        .mix(ENSEMBL_GENESET_DOWNLOAD.out.cdna)
        .mix(ENSEMBL_GENESET_DOWNLOAD.out.pep)
        .map { meta, fasta ->
            [
                meta + [id: fasta.baseName],
                fasta,
            ]
        }

    // tuple(meta,gff) at this stage
    ch_gff = ENSEMBL_GENESET_DOWNLOAD.out.gff.map { meta, gff ->
        [
            meta + [id: gff.baseName],
            gff,
        ]
    }

    // 2. Repeat masking

    ch_genome_fasta = ENSEMBL_GENOME_DOWNLOAD(
        annotation_params.map { outdir, assembly_accession, annotation_method, geneset_version ->
            [
                // meta
                [
                    id: assembly_accession + ".repeats.ensembl",
                    assembly_accession: assembly_accession,
                    geneset_version: geneset_version,
                    method: annotation_method,
                    outdir: outdir,
                ],

                // ftp_path
                // Turn "GCA_927399515.1" to "GCA/927/399/515/1"
                // e.g. https://ftp.ebi.ac.uk/pub/ensemblorganisms/GCA/905/163/415/1/braker/2022_03/geneset/cdna.fa.bgz
                [
                    params.ftp_root,
                    "GCA",
                    assembly_accession.substring(4, 7),
                    assembly_accession.substring(7, 10),
                    assembly_accession.substring(10, 13),
                    assembly_accession.substring(14),
                    annotation_method,
                    geneset_version,
                    "genome",
                ].join("/")
            ]
        }
    ).fasta

    emit:
    genes  = ch_all_gene_fasta // path: (cdna|cds|pep).fa
    gff    = ch_gff // path: genes.gff
    genome = ch_genome_fasta // path: genome.fa
}
