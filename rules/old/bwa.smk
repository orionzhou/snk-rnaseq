def bwa_inputs(w):
    sid = w.sid
    idir = config['bwa']['idir']
    inputs = dict()
    if config['t'][sid]['paired']:
        inputs['fq1'] = "%s/%s_1.fq.gz" % (idir, sid)
        inputs['fq2'] = "%s/%s_2.fq.gz" % (idir, sid)
    else:
        inputs['fq'] = "%s/%s.fq.gz" % (idir, sid)
    return inputs

def bwa_extra(w):
    extras = [config["bwa"]["extra"]]
    sm = w.sid
    if 'Genotype' in config['t'][w.sid]:
        sm = config['t'][w.sid]['Genotype']
    pl = 'ILLUMINA'
    if config['readtype'] == 'solid':
        pl = 'SOLID'
    extras.append("-R '@RG\\tID:%s\\tSM:%s\\tPL:%s'" % (w.sid, sm, pl))
    return " ".join(extras)

rule bwa:
    input:
        unpack(bwa_inputs)
    log:
        "%s/%s/{sid}.log" % (config['dirl'], config['bwa']['id'])
    output:
        temp("%s/{sid}.sam" % config['bwa']['odir1'])
    params:
        index = config[config['reference']]["bwa"],
        extra = bwa_extra,
        N = lambda w: "%s.%s" % (config['bwa']['id'], w.sid),
        e = lambda w: "%s/%s/%s.e" % (config['dirp'], config['bwa']['id'], w.sid),
        o = lambda w: "%s/%s/%s.o" % (config['dirp'], config['bwa']['id'], w.sid),
        q = lambda w, resources: resources.q,
        ppn = lambda w, resources: resources.ppn,
        runtime = lambda w, resources: resources.runtime,
        mem = lambda w, resources: resources.mem
    resources:
        q = lambda w, attempt:  get_resource(config, attempt, 'bwa')['q'],
        ppn = lambda w, attempt: get_resource(config, attempt, 'bwa')['ppn'],
        runtime = lambda w, attempt: get_resource(config, attempt, 'bwa')['runtime'],
        mem = lambda w, attempt: get_resource(config, attempt, 'bwa')['mem']
    threads: config['bwa']['ppn']
    run:
        if config['t'][wildcards.sid]['paired']:
            shell("""
            bwa mem -t {threads} {params.index} {params.extra} {input.fq1} {input.fq2} \
                    >{output} 2>>{log}
            """)
        else:
            shell("""
            bwa mem -t {threads} {params.index} {params.extra} {input.fq} \
                    >{output} 2>>{log}
            """)

