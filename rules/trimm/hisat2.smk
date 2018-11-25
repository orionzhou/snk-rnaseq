def hisat2_inputs(wildcards):
    sid = wildcards.sid
    inputs = dict()
    if config['t'][wildcards.sid]['paired']:
        inputs['fq1'] = "%s/%s_1.fq.gz" % (config['hisat2']['idir'], sid)
        inputs['fq2'] = "%s/%s_2.fq.gz" % (config['hisat2']['idir'], sid)
        inputs['fq1u'] = "%s/%s_1.unpaired.fq.gz" % (config['hisat2']['idir'], sid)
        inputs['fq2u'] = "%s/%s_2.unpaired.fq.gz" % (config['hisat2']['idir'], sid)
    else:
        inputs['fq'] = "%s/%s.fq.gz" % (config['hisat2']['idir'], sid)
    return inputs

def hisat2_input_str(wildcards):
    sid = wildcards.sid
    input_str = ''
    if config['t'][wildcards.sid]['paired']:
        fq1 = "%s/%s_1.fq.gz" % (config['hisat2']['idir'], sid)
        fq2 = "%s/%s_2.fq.gz" % (config['hisat2']['idir'], sid)
        fq1u = "%s/%s_1.unpaired.fq.gz" % (config['hisat2']['idir'], sid)
        fq2u = "%s/%s_2.unpaired.fq.gz" % (config['hisat2']['idir'], sid)
        input_str = "-1 %s -2 %s -U %s,%s" % (fq1, fq2, fq1u, fq2u)
    else:
        fq = "%s/%s.fq.gz" % (config['hisat2']['idir'], sid)
        input_str = "-U %s" % fq
    return input_str

def hisat2_extra(wildcards):
    extras = [config["hisat2"]["extra"]]
    extras.append("--rg-id %s --rg SM:%s" % (wildcards.sid, wildcards.sid))
    return " ".join(extras)

rule hisat2:
    input: 
        unpack(hisat2_inputs)
    output:
        temp("%s/{sid}.bam" % config['hisat2']['odir1']),
        protected("%s/{sid}.txt" % config['hisat2']['odir1'])
    params:
        index = config[config['reference']]["hisat2"],
        input_str = hisat2_input_str,
        extra = hisat2_extra,
        N = lambda w: "%s.%s" % (config['hisat2']['id'], w.sid),
        e = lambda w: "%s/%s/%s.e" % (config['dirp'], config['hisat2']['id'], w.sid),
        o = lambda w: "%s/%s/%s.o" % (config['dirp'], config['hisat2']['id'], w.sid),
        ppn = lambda w, resources: resources.ppn,
        runtime = lambda w, resources: resources.runtime,
        mem = lambda w, resources: resources.mem
    resources:
        ppn = lambda w, attempt:  get_resource(config, attempt, 'hisat2')['ppn'],
        runtime = lambda w, attempt:  get_resource(config, attempt, 'hisat2')['runtime'],
        mem = lambda w, attempt:  get_resource(config, attempt, 'hisat2')['mem']
    threads: config['hisat2']['ppn']
    shell:
        """
        hisat2 {params.extra} --threads {threads} \
            -x {params.index} {params.input_str} \
            --summary-file {output[1]} \
            | samtools view -Sbh -o {output[0]} -
        """

rule sambamba_sort:
    input:
        "%s/{sid}.bam" % config['hisat2']['odir1']
    output: 
        protected("%s/{sid}.bam" % config['hisat2']['odir2'])
    params:
        extra = "--tmpdir=%s %s" % (config['tmpdir'], config['sambamba']['sort']['extra']),
        N = lambda w: "%s.%s" % (config['sambamba']['sort']['id'], w.sid),
        e = lambda w: "%s/%s/%s.e" % (config['dirp'], config['sambamba']['sort']['id'], w.sid),
        o = lambda w: "%s/%s/%s.o" % (config['dirp'], config['sambamba']['sort']['id'], w.sid),
        ppn = lambda w, resources: resources.ppn,
        runtime = lambda w, resources: resources.runtime,
        mem = lambda w, resources: resources.mem
    resources:
        ppn = lambda w, attempt:  get_resource(config, attempt, 'sambamba', 'sort')['ppn'],
        runtime = lambda w, attempt:  get_resource(config, attempt, 'sambamba', 'sort')['runtime'],
        mem = lambda w, attempt:  get_resource(config, attempt, 'sambamba', 'sort')['mem']
    threads: config['sambamba']['ppn']
    shell:
        """
        sambamba sort {params.extra} -t {threads} -o {output} {input}
        """

rule bam_stat:
    input:
        "%s/{sid}.bam" % config['hisat2']['odir2']
    output:
        protected("%s/{sid}.tsv" % config['hisat2']['odir2'])
    params:
        N = lambda w: "%s.%s" % (config['bam_stat']['id'], w.sid),
        e = lambda w: "%s/%s/%s.e" % (config['dirp'], config['bam_stat']['id'], w.sid),
        o = lambda w: "%s/%s/%s.o" % (config['dirp'], config['bam_stat']['id'], w.sid),
        ppn = lambda w, resources: resources.ppn,
        runtime = lambda w, resources: resources.runtime,
        mem = lambda w, resources: resources.mem
    resources:
        ppn = lambda w, attempt:  get_resource(config, attempt, 'bam_stat')['ppn'],
        runtime = lambda w, attempt:  get_resource(config, attempt, 'bam_stat')['runtime'],
        mem = lambda w, attempt:  get_resource(config, attempt, 'bam_stat')['mem']
    threads: config['bam_stat']['ppn']
    shell:
        "bam stat {input} > {output}"

