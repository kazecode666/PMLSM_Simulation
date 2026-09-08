function validate_half_ts
% Verify non-default PWM timing without changing saved model defaults.
m='PMLSM_ThreeLoop_Simple';
results={};
for period=[100e-6 80e-6]
 in=Simulink.SimulationInput(m);
 values=struct('Ts',period,'Ts_ACR',period,'Ts_ASR',10*period, ...
  'Ts_POS',100*period,'PMLSM_Ts_s',period/2, ...
  'PMLSM_pwm_period_counts',200e6*period/2, ...
  'PMLSM_deadtime_ratio',1e-6/period,'Host_Start_s',0.002,'Host_Target_mm',1, ...
  'Kp_ACR',1.745e-3/(4*period),'Ki_ACR',2.37/(4*period));
 names=fieldnames(values);
 for j=1:numel(names), in=in.setVariable(names{j},values.(names{j}),'Workspace',m); end
 in=in.setModelParameter('StopTime','0.05'); out=sim(in);
 a=out.applied_counts; c=out.compare_counts;
 assert(max(abs(diff(a.Time)-period/2))<1e-10);
 assert(max(abs(diff(c.Time)-period))<1e-10);
 assert(max(c.Data,[],'all')-min(c.Data,[],'all')>1,'Need varying compare values');
 ix=floor((a.Time(2:end)-period/2+1e-10)/period)+1;
 err=max(abs(a.Data(2:end,:)-c.Data(ix,:)),[],'all'); assert(err<1e-8);
 assert(all(a.Data(1,:)==values.PMLSM_pwm_period_counts/2));
 s=out.speed_tick.Time(logical(out.speed_tick.Data));
 p=out.position_tick.Time(logical(out.position_tick.Data));
 assert(max(abs(diff(s)-10*period))<1e-10);
 assert(max(abs(diff(p)-100*period))<1e-10);
 r=struct('Ts_s',period,'PWM_delay_s',period/2,'delay_error_counts',err, ...
  'speed_period_s',10*period,'position_period_s',100*period);
 results{end+1}=r; fprintf('HALF_TS_PASS %s\n',jsonencode(r)); %#ok<AGROW>
end
fid=fopen('docs/half_ts_validation.json','w');
fprintf(fid,'%s',jsonencode([results{:}],'PrettyPrint',true));fclose(fid);
end
