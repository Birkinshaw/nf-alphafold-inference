#!/usr/bin/env nextflow
import java.text.SimpleDateFormat
println "*****************************************************"
println "*  Nextflow <name> pipeline                         *"
println "*  A Nextflow wrapper pipeline                      *"
println "*  Written by Julie Iskander,                       *"
println "*              Research Computing Platform          *"
println "*  research.computing@wehi.edu.au                   *"
println "*                                                   *"
println "*****************************************************"
println " Required Pipeline parameters                        "
println "-----------------------------------------------------"
println "Input  Directory   : $params.inputdir                "
println "Output Directory   : $params.outdir                  " 
println "Fasta Directory    : $params.fastadir                "
println "*****************************************************"


include {  ALPHAFOLD_Inference as Multimer_Inference } from './modules/alphafold.nf'



workflow {

    // Load existing feature directories
    def feature_ch = Channel.fromPath(params.inputdir+"/*/", type: 'dir', checkIfExists:true)
                          .ifEmpty {
                                    error("""
                                    No feature directories could be found! Please check whether your input directory
                                    is correct, and that feature directories exist.
                                    """)
                          }
                          .map { dir ->
                              def sample_name = dir.name
                              // find the appropriate fasta file
                              def source_fasta = file("${params.fastadir}/${sample_name}.fasta")
                              def dest_fasta = file("${params.inputdir}/${sample_name}.fasta")

                              // Check if FASTA file exists
                              if (!source_fasta.exists()) {
                                  error("FASTA file not found: ${source_fasta}")
                              }
                              // Copy the fasta file
                              source_fasta.copyTo(dest_fasta)
    
                              return tuple(sample_name, dir, dest_fasta, "multimer")
                          }
    
    Channel.from(params.model_indices.split(',').toList())
           .set { model_indicies_ch }
    
    // Run multimer inference only
    Multimer_Inference(feature_ch.combine(model_indicies_ch))
    
}
