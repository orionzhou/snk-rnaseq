def fq_compress_inputs(w):
    yid, sid = w.yid, w.sid
    inputs = dict()
    if config['y'][yid]['t'][sid]['paired']:
        inputs['r1'] = config['y'][yid]['t'][sid]['r1']
        inputs['r2'] = config['y'][yid]['t'][sid]['r2']
    else:
        inputs['r0'] = config['y'][yid]['t'][sid]['r0']
    return inputs

rule fq_compress:
    input: unpack(fq_compress_inputs)
    output:
        r0 = "{yid}/%s/{sid}.fq.gz" % config['fq_compress']['odir'],
        r1 = "{yid}/%s/{sid}_1.fq.gz" % config['fq_compress']['odir'],
        r2 = "{yid}/%s/{sid}_2.fq.gz" % config['fq_compress']['odir']
    params:
        N = "{yid}.%s.{sid}" % config['fq_compress']['id'],
        e = "{yid}/%s/%s/{sid}.e" % (config['dirj'], config['fq_compress']['id']),
        o = "{yid}/%s/%s/{sid}.o" % (config['dirj'], config['fq_compress']['id']),
        j = lambda w: get_resource(w, config, 'fq_compress'),
    resources: attempt = lambda w, attempt: attempt
    threads: lambda w: get_resource(w, config, 'fq_compress')['ppn']
    conda: "../envs/work.yml"
    script: "../scripts/fq_compress.py"

rule fq_deinterleave:
    input: lambda w: config['y'][w.yid]['t'][w.sid]['r0']
    output:
        r0 = "{yid}/%s/{sid}.fq.gz" % config['fq_deinterleave']['odir'],
        r1 = "{yid}/%s/{sid}_1.fq.gz" % config['fq_deinterleave']['odir'],
        r2 = "{yid}/%s/{sid}_2.fq.gz" % config['fq_deinterleave']['odir']
    params:
        N = "{yid}.%s.{sid}" % config['fq_deinterleave']['id'],
        e = "{yid}/%s/%s/{sid}.e" % (config['dirj'], config['fq_deinterleave']['id']),
        o = "{yid}/%s/%s/{sid}.o" % (config['dirj'], config['fq_deinterleave']['id']),
        j = lambda w: get_resource(w, config, 'fq_deinterleave'),
    resources: attempt = lambda w, attempt: attempt
    threads: lambda w: get_resource(w, config, 'fq_deinterleave')['ppn']
    conda: "../envs/work.yml"
    shell:
        """
        zcat {input} | \
            deinterleave_fastq.sh {output.r1} {output.r2} {threads} compress
        touch {output.r0}
        """

rule fq_dump:
    input:
    output:
        r0 = "{yid}/%s/{sid}.fq.gz" % config['fq_dump']['odir'],
        r1 = "{yid}/%s/{sid}_1.fq.gz" % config['fq_dump']['odir'],
        r2 = "{yid}/%s/{sid}_2.fq.gz" % config['fq_dump']['odir']
    params:
        odir = "{yid}/%s" % config['fq_dump']['odir'],
        o0 = "{yid}/%s/{sid}.fastq" % config['fq_dump']['odir'],
        o1 = "{yid}/%s/{sid}_1.fastq" % config['fq_dump']['odir'],
        o2 = "{yid}/%s/{sid}_2.fastq" % config['fq_dump']['odir'],
        tmp = config['tmpdir'],
        N = "{yid}.%s.{sid}" % config['fq_dump']['id'],
        e = "{yid}/%s/%s/{sid}.e" % (config['dirj'], config['fq_dump']['id']),
        o = "{yid}/%s/%s/{sid}.o" % (config['dirj'], config['fq_dump']['id']),
        j = lambda w: get_resource(w, config, 'fq_dump'),
        mem = lambda w: get_resource(w, config, 'fq_dump')['mem'],
    resources:
        attempt = lambda w, attempt: attempt,
        load = lambda w: get_resource(w, config, 'fq_dump')['load'],
    threads: lambda w: get_resource(w, config, 'fq_dump')['ppn']
    conda: "../envs/work.yml"
    script: "../scripts/fq_dump.py"

def fastq_inputs(w):
    yid, sid = w.yid, w.sid
    source = config['y'][yid]['source']
    assert source in config['valid']['source'], "invalid source: %s" % source
    idir = ''
    if source == 'sra':
        idir = config['fq_dump']['odir']
    elif source == 'local':
        idir = config['fq_compress']['odir']
    elif source == 'local_interleaved':
        idir = config['fq_deinterleave']['odir']
    pre = op.abspath("%s/%s/%s" % (yid, idir, sid))
    pre = "%s/%s/%s" % (yid, idir, sid)
    inputs = {
        'r0': "%s.fq.gz" % pre,
        'r1': "%s_1.fq.gz" % pre,
        'r2': "%s_2.fq.gz" % pre,
    }
    return inputs

rule fastq:
    input: unpack(fastq_inputs)
    output:
        r0 = "{yid}/%s/{sid}.fq.gz" % config['fastq']['odir'],
        r1 = "{yid}/%s/{sid}_1.fq.gz" % config['fastq']['odir'],
        r2 = "{yid}/%s/{sid}_2.fq.gz" % config['fastq']['odir'],
    run:
        shell("ln -sf %s %s" % (op.abspath(input.r0), output.r0))
        shell("ln -sf %s %s" % (op.abspath(input.r1), output.r1))
        shell("ln -sf %s %s" % (op.abspath(input.r2), output.r2))


