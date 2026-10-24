import argparse
import json
import math
import os
from pathlib import Path
import sys

os.environ.setdefault('MPLCONFIGDIR', '/tmp/simd-matplotlib')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import pandas as pd

KEYS = ['study','build','kernel','dtype','n','offset_bytes','stride','footprint_bytes',
        'active_bytes','flops_per_element','logical_bytes_per_element']
REQUIRED = KEYS + ['rep','warmup','iterations','seconds','cycles','checksum']
COLORS = {'scalar':'#555555','auto':'#2271b2','native':'#d55e00'}


def metrics(d):
    d=d.copy()
    work=d['n']*d['iterations']
    d['runtime_s']=d['seconds']/d['iterations']
    d['ns_per_element']=d['seconds']/work*1e9
    d['gflops']=work*d['flops_per_element']/d['seconds']/1e9
    d['gibps']=work*d['logical_bytes_per_element']/d['seconds']/2**30
    d['cycles_per_element']=d['cycles']/work
    return d


def summarize(d):
    d=metrics(d)
    values=['runtime_s','ns_per_element','gflops','gibps','cycles_per_element']
    s=d.groupby(KEYS,dropna=False,sort=True)[values].agg(['mean','std','median','count'])
    s.columns=['_'.join(c) for c in s.columns]
    s=s.reset_index()
    match=[k for k in KEYS if k!='build']
    scalar=s[s['build']=='scalar'][match+['runtime_s_mean','runtime_s_std']].rename(
        columns={'runtime_s_mean':'scalar_time','runtime_s_std':'scalar_std'})
    s=s.merge(scalar,on=match,how='left',validate='many_to_one')
    s['speedup']=s['scalar_time']/s['runtime_s_mean']
    s['speedup_sd']=s['speedup']*((s['scalar_std']/s['scalar_time'])**2 +
                                 (s['runtime_s_std']/s['runtime_s_mean'])**2)**0.5
    s.loc[s['build']=='scalar','speedup']=1.0
    s.loc[s['build']=='scalar','speedup_sd']=0.0
    return s


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('run',type=Path)
    p.add_argument('--peak-f32',type=float)
    p.add_argument('--peak-f64',type=float)
    p.add_argument('--peak-note')
    args=p.parse_args()
    raw=args.run/'raw.csv'; env=args.run/'environment.json'
    if not raw.exists(): p.error(f'{raw} missing: run experiments first')
    if not env.exists(): p.error(f'{env} missing: environment info is required')
    for peak in (args.peak_f32,args.peak_f64):
        if peak is not None and (not math.isfinite(peak) or peak<=0): p.error('Estimates must be +')
    if (args.peak_f32 or args.peak_f64) and not args.peak_note:
        p.error('--peak-note is required with a peak estimate, do not guess CPU peak')
    d=pd.read_csv(raw)
    missing=set(REQUIRED)-set(d.columns)
    if missing: p.error(f'CSV missing columns: {sorted(missing)}')
    if d.empty: p.error('CSV has no measurements correctness-only, runs do not generate performance data')
    for name in set(REQUIRED)-{'study','build','kernel','dtype'}:
        d[name]=pd.to_numeric(d[name],errors='raise')
    if d[[c for c in REQUIRED if c!='cycles']].isna().any().any(): p.error('Missing required CSV values')
    if not d['build'].isin(COLORS).all() or not d['kernel'].isin(['saxpy','dot','mul']).all() or not d['dtype'].isin(['f32','f64']).all():
        p.error('Unknown build, kernel, or dtype')
    for c in ['seconds','iterations','n']:
        if not d[c].map(lambda v: math.isfinite(v) and v>0).all(): p.error(f'{c} must be finite and positive')
    for row in d.itertuples():
        b=4 if row.dtype=='f32' else 8
        arrays=3 if row.kernel=='mul' else 2
        expected=(1 if row.kernel=='mul' else 2, (2 if row.kernel=='dot' else 3)*b,
                  arrays*((row.n-1)*row.stride+1)*b, arrays*row.n*b)
        if (row.flops_per_element,row.logical_bytes_per_element,row.footprint_bytes,row.active_bytes)!=expected:
            p.error('CSV operation count, traffic, or footprint disagrees with kernel schema')
    metadata=json.loads(env.read_text()); cfg=metadata['configuration']
    out=args.run/'processed'; out.mkdir(exist_ok=True)
    s=summarize(d); s.to_csv(out/'summary.csv',index=False)
    notes=[]; made=[]
    def warn(message):
        notes.append(message); print('warning: '+message,file=sys.stderr)
    plan_path=args.run/'plan.csv'
    if plan_path.exists():
        plan=pd.read_csv(plan_path)
        case_keys=['study','build','kernel','dtype','n','offset_bytes','stride']
        counts=d.groupby(case_keys).size().reset_index(name='observed_reps')
        coverage=plan[case_keys].drop_duplicates().merge(counts,on=case_keys,how='left')
        incomplete=coverage[coverage.observed_reps.fillna(0)<cfg['reps']]
        if not incomplete.empty:
            warn(f'{len(incomplete)} planned configurations have missing repetitions or no measurements; inspect coverage.csv.')
        coverage.to_csv(out/'coverage.csv',index=False)
    else:
        warn('plan.csv missing; completeness against the intended configurations cannot be checked.')
    if s['runtime_s_count'].min()<2: warn('Some configurations have fewer than two repetitions.')
    if s['speedup'].isna().any(): warn('Some configurations lack a matching scalar baseline.')
    if d['cycles'].isna().any(): warn('Hardware cycles unavailable for some/all rows.')
    if not metadata.get('pinning_active'): warn('CPU pinning was inactive.')
    def subset(study):
        q=s[s.study==study]
        if q.empty: warn(f'{study}: measurements missing, figure skipped.')
        return q
    def save(fig,name):
        fig.tight_layout(); fig.savefig(out/(name+'.png'),dpi=160); plt.close(fig); made.append(name+'.png')
    def line(ax,g,x,metric,label,color=None,style='-'):
        g=g.sort_values(x)
        mean=metric+'_mean' if metric!='speedup' else 'speedup'
        sd=metric+'_std' if metric!='speedup' else 'speedup_sd'
        ax.errorbar(g[x],g[mean],yerr=g[sd].fillna(0),label=label,color=color,
                    marker='o',markersize=3,capsize=2,linestyle=style)
    def cache_lines(ax):
        for key,label in [('l1_bytes','L1'),('l2_bytes','L2'),('llc_bytes','LLC')]:
            value=cfg.get(key,0)
            if value:
                ax.axvline(value,color='gray',linestyle=':',alpha=.6)
                ax.text(value,0.98,label,transform=ax.get_xaxis_transform(),va='top',ha='right',fontsize=8)
    def grid(title):
        fig,axs=plt.subplots(3,2,figsize=(11,10),squeeze=False)
        fig.suptitle(title+'; bars = sample SD',fontsize=11)
        for i,k in enumerate(('saxpy','dot','mul')):
            for j,t in enumerate(('f32','f64')):
                axs[i,j].set_title(f'{k}, {t}')
                axs[i,j].grid(alpha=.2)
        return fig,axs
    q=subset('baseline')
    if not q.empty:
        for metric,name,ylabel in [('speedup','speedup','Speedup over scalar (x)'),
                                  ('gflops','throughput','Achieved GFLOP/s')]:
            fig,axs=grid('Across working-set sizes'+(' (propagated SD)' if metric=='speedup' else ''))
            for i,k in enumerate(('saxpy','dot','mul')):
                for j,t in enumerate(('f32','f64')):
                    ax=axs[i,j]
                    for build in COLORS:
                        g=q[(q.kernel==k)&(q.dtype==t)&(q.build==build)]
                        if not g.empty: line(ax,g,'footprint_bytes',metric,build,COLORS[build])
                    ax.set_xscale('log',base=2); ax.set_xlabel('Working-set span (bytes)'); ax.set_ylabel(ylabel); ax.legend(fontsize=8)
            save(fig,name)
    q=subset('locality')
    if not q.empty:
        fig,axs=plt.subplots(2,2,figsize=(11,8),squeeze=False)
        fig.suptitle('SAXPY locality: compare speedup compression with bandwidth plateau; bars = SD')
        for i,t in enumerate(('f32','f64')):
            for j,metric in enumerate(('speedup','gibps')):
                ax=axs[i,j]
                for build in COLORS:
                    g=q[(q.dtype==t)&(q.build==build)]
                    if not g.empty: line(ax,g,'footprint_bytes',metric,build,COLORS[build])
                cache_lines(ax); ax.set_xscale('log',base=2); ax.set_title(t)
                ax.set_xlabel('Working-set span (bytes)'); ax.set_ylabel('Speedup over scalar ()' if j==0 else 'Logical GiB/s')
                ax.grid(alpha=.2); ax.legend()
                native=q[(q.dtype==t)&(q.build=='native')].sort_values('footprint_bytes')
                cached=native[native.footprint_bytes<=cfg.get('llc_bytes',0)/2]
                if j==0 and not native.empty and not cached.empty:
                    ax.text(.02,.03,f'Native: best cached {cached.speedup.max():.2f}x; largest {native.iloc[-1].speedup:.2f}x',
                            transform=ax.transAxes,fontsize=8)
        save(fig,'locality')
    q=subset('alignment')
    if not q.empty:
        fig,axs=grid('Alignment and tails: quantify the small-N overhead and large-N cost')
        for i,k in enumerate(('saxpy','dot','mul')):
            for j,t in enumerate(('f32','f64')):
                ax=axs[i,j]; g=q[(q.kernel==k)&(q.dtype==t)]
                sizes=sorted(g.n.unique()); positions={n:i for i,n in enumerate(sizes)}
                for (build,offset),h in g.groupby(['build','offset_bytes']):
                    h=h.copy(); h['position']=h.n.map(positions)
                    line(ax,h,'position','ns_per_element',f'{build}, +{offset} B',COLORS[build],'-' if offset==0 else '--')
                ax.set_xticks(range(len(sizes)),[str(n) for n in sizes],rotation=40)
                ax.set_xlabel('N (confirm remainders from assembly width)'); ax.set_ylabel('ns / active element'); ax.legend(fontsize=7)
        save(fig,'alignment_tail')
    q=subset('stride')
    if not q.empty:
        for metric,name,label in [('gibps','stride','Logical GiB/s'),('speedup','stride_speedup','Speedup over scalar (x)')]:
            fig,axs=grid('Stride at fixed active element count (span grows with stride)')
            for i,k in enumerate(('saxpy','dot','mul')):
                for j,t in enumerate(('f32','f64')):
                    ax=axs[i,j]
                    for (build,n),g in q[(q.kernel==k)&(q.dtype==t)].groupby(['build','n']):
                        line(ax,g,'stride',metric,f'{build}, N={n}',COLORS[build],'-' if n==q.n.min() else '--')
                    ax.set_xticks([1,2,4,8]); ax.set_xlabel('Stride (elements)'); ax.set_ylabel(label); ax.legend(fontsize=6)
            save(fig,name)
        q.to_csv(out/'stride_summary.csv',index=False)
    q=subset('dtype')
    if not q.empty:
        fig,axs=plt.subplots(1,3,figsize=(14,4),squeeze=False)
        fig.suptitle('Data types at matched working-set bytes; bars = sample SD')
        for j,k in enumerate(('saxpy','dot','mul')):
            ax=axs[0,j]
            for (build,t),g in q[q.kernel==k].groupby(['build','dtype']):
                line(ax,g,'footprint_bytes','gflops',f'{build}, {t}',COLORS[build],'-' if t=='f32' else '--')
            ax.set_xscale('log',base=2); ax.set_title(k); ax.set_xlabel('Working-set span (bytes)'); ax.set_ylabel('GFLOP/s'); ax.legend(fontsize=7)
        save(fig,'dtype')
    q=subset('negative')
    if not q.empty:
        fig,axs=plt.subplots(1,2,figsize=(10,4),squeeze=False)
        fig.suptitle('DRAM-sized SAXPY: candidate negative case; verify measured speedup')
        for j,t in enumerate(('f32','f64')):
            ax=axs[0,j]
            for pos,build in enumerate(COLORS):
                g=q[(q.dtype==t)&(q.build==build)]
                if len(g)>1: warn('Negative study has multiple sizes; displayed points are offset slightly.')
                for v,row in enumerate(g.itertuples()):
                    ax.errorbar(pos+.05*v,row.speedup,yerr=0 if pd.isna(row.speedup_sd) else row.speedup_sd,
                                fmt='o',color=COLORS[build],capsize=4)
            ax.axhline(1,color='gray',linestyle=':'); ax.set_xticks(range(3),list(COLORS)); ax.set_title(t)
            ax.set_ylabel('Speedup over scalar (x), propagated SD'); ax.grid(alpha=.2)
        save(fig,'negative')
    roof=subset('roofline'); bandwidth=subset('bandwidth')
    roof_records=[]
    if not roof.empty and not bandwidth.empty:
        for t,peak in [('f32',args.peak_f32),('f64',args.peak_f64)]:
            if peak is None:
                warn(f'Roofline {t}: pending documented --peak-{t}; no CPU peak is assumed.'); continue
            cal=bandwidth[(bandwidth.dtype==t)&(bandwidth.build=='native')]
            if len(cal)!=1:
                warn(f'Roofline {t}: expected one native DRAM bandwidth calibration, found {len(cal)}.'); continue
            row=cal.iloc[0]
            if cfg.get('llc_bytes',0)<=0 or row.footprint_bytes<2*cfg['llc_bytes']:
                warn(f'Roofline {t}: calibration not verified larger than LLC; figure skipped.'); continue
            bw=row.gibps_mean*2**30 # Logical bytes/s of measured one-thread native SAXPY.
            fig,ax=plt.subplots(figsize=(8,5))
            xs=[10**(-3+i*6/199) for i in range(200)]
            ax.loglog(xs,[min(peak,bw*x/1e9) for x in xs],label='DRAM logical bandwidth + estimated peak',color='black')
            ax.axhline(peak,color='gray',linestyle=':',label='Estimated one-core peak')
            for (build,n),g in roof[roof.dtype==t].groupby(['build','n']):
                for r in g.itertuples():
                    intensity=r.flops_per_element/r.logical_bytes_per_element
                    ax.errorbar(intensity,r.gflops_mean,yerr=0 if pd.isna(r.gflops_std) else r.gflops_std,
                                fmt='o',capsize=3,color=COLORS[build],label=f'{build}, {r.footprint_bytes/2**20:.3g} MiB')
                    roof_records.append({'dtype':t,'build':build,'n':n,'arithmetic_intensity_flops_per_logical_byte':intensity,
                                         'measured_bandwidth_logical_bytes_s':bw,'estimated_peak_gflops':peak,
                                         'dram_roof_gflops':min(peak,bw*intensity/1e9),'achieved_gflops':r.gflops_mean})
            ax.set_xlabel('Arithmetic intensity (FLOP / logical byte)'); ax.set_ylabel('GFLOP/s')
            ax.set_title(f'SAXPY {t}: DRAM roof; cached points can exceed it\nBandwidth = measured SAXPY logical traffic; bars = SD')
            ax.grid(alpha=.2); ax.legend(fontsize=7,loc='center left',bbox_to_anchor=(1,0.5))
            save(fig,'roofline_'+t)
    if roof_records: pd.DataFrame(roof_records).to_csv(out/'roofline_summary.csv',index=False)
    (out/'analysis.json').write_text(json.dumps({'peak_f32':args.peak_f32,'peak_f64':args.peak_f64,
        'peak_note':args.peak_note,'figures':made,'warnings':notes,
        'error_bars':'sample SD; speedup uses first-order propagation of independent sample SDs; not confidence intervals',
        'bandwidth':'measured logical SAXPY traffic, not hardware memory-controller bytes'},indent=2)+'\n')
    print(f'Processed: {out}')


if __name__=='__main__':
    main()
