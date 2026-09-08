function verify_three_loop_tuning
% Run in an isolated directory containing model, init and design function.
m='PMLSM_ThreeLoop_Simple';open_system(m);
[files,missing]=dependencies.fileDependencyAnalysis(m,'AnalyzeToolboxFiles',false);
assert(isempty(missing));
assert(all(startsWith(lower(string(files)),lower(string(pwd)))));
w=get_param(m,'ModelWorkspace');g=w.getVariable('Tuning_Gains');
assert(abs(g.Kp_ACR-8.725)<1e-10 && abs(g.Ki_ACR-11850)<1e-8);
assert(abs(g.Kp_ASR-0.018033474852681124)<1e-12 && abs(g.Kp_pos-22)<1e-10);
assert(w.getVariable('v_ref_zero_eps')==0);
rows={};
for loadN=[0 2]
 in=Simulink.SimulationInput(m);
 in=in.setVariable('Host_Load_N',loadN,'Workspace',m);
 in=in.setModelParameter('StopTime','3');o=sim(in);
 names={'x_ref_mm','x_mm','ia','ib','ic','iq_ref','iq','id_ref','id','ud','uq','v_mmps','v_ref'};
 assert(isequal(sort(o.logsout.getElementNames),sort(names(:))));
 for k=1:numel(names)
  v=o.logsout.get(names{k}).Values;assert(all(isfinite(v.Data(:))));
 end
 x=o.logsout.get('x_mm').Values;v=o.logsout.get('v_mmps').Values;
 tail=x.Time>=2.5;err=max(abs(x.Data(tail)-10));assert(err<.05);
 r=struct('load_N',loadN,'tail_max_error_mm',err,'final_x_mm',x.Data(end),'final_v_mmps',v.Data(end));
 rows{end+1}=r;fprintf('ISOLATED_PASS %s\n',jsonencode(r)); %#ok<AGROW>
end
result=struct('release',version,'directory',pwd,'gains',g,'results',{rows});
fid=fopen('isolated_tuning_validation.json','w');fprintf(fid,'%s',jsonencode(result,'PrettyPrint',true));fclose(fid);
fprintf('ISOLATED_TUNING_PASS\n');
end
