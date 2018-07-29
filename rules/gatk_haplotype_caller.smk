def gatk_hc_cmd(wildcards):
    java_mem = config['java']['mem']
    if 'java_mem' in config['gatk']:
        java_mem = config['gatk']['java_mem']
    if 'java_mem' in config['gatk']['haplotype_caller']:
        java_mem = config['gatk']['haplotype_caller']['java_mem']
    java_tmpdir = config['tmpdir']
    if 'tmpdir' in config['java']:
        java_tmpdir = config['java']['tmpdir']
    java_options = "-Xmx%s -Djava.io.tmpdir=%s" % (java_mem, java_tmpdir)
    cmd = "%s --java-options \"%s\"" % (config['gatk']['cmd'], java_options)
    return cmd

rule gatk_haplotype_caller:
    input:
        "%s/{sid}.bam" % config['gatk']['idir']
    output:
        temp("%s/{sid}/{region}.g.vcf.gz" % config['gatk']['odir'])
    log:
        "%s/gatk/{sid}/{region}.log" % config['dirl']
    params:
        cmd = gatk_hc_cmd,
        ref = config['gatk']['ref'],
        extra = config['gatk']['haplotype_caller']['extra'],
    threads:
        config["gatk"]['haplotype_caller']["threads"]
    shell:
        #-G StandardAnnotation -G AS_StandardAnnotation -G StandardHCAnnotation \
        """
        {params.cmd} HaplotypeCaller \
        -R {params.ref} \
        -ERC GVCF \
        -L {wildcards.region} \
        {params.extra} \
        -I {input} \
        -O {output} \
        >{log} 2>&1
        """

rule gatk_gather_vcfs:
    input:
        lambda wildcards: ["%s/%s/%s.g.vcf.gz" % 
            (config['gatk']['odir'], wildcards.sid, x) 
            for x in config['gatk']['gather_vcfs']['regions'].split(" ")]
    output:
        temp("%s/{sid}.g.vcf.gz" % config['gatk']['odir'])
    log:
        "%s/gatk/{sid}.log" % config['dirl']
    params:
        cmd = config['gatk']['cmd'],
        input_str = lambda wildcards, input: ["-I %s" % x for x in input],
        extra = config['gatk']['gather_vcfs']['extra']
    threads:
        config["gatk"]['gather_vcfs']["threads"]
    shell:
        "{params.cmd} GatherVcfs {params.input_str} -O {output} >{log} 2>&1"
