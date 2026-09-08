function validate_enable_logic
m='PMLSM_ThreeLoop_Simple'; report={};
cases={ ...
 'position',[0 1 1 1],0,0,0,0,3; ...
 'speed',[0 1 0 1],5,0,0,0,1; ...
 'closed_off',[0 0 1 1],5,0,0,0,0.3; ...
 'pwm_off',[0 1 1 0],0,0,0,0,0.3; ...
 'switching',[0 1 1 1;0.4 0 1 1;0.6 1 0 1;0.8 1 0 0;1 1 0 1;1.2 1 1 1],5,0,0,0,4; ...
 'current_only',[0 0 0 1],0,1,0.05,0,0.08; ...
 'pi_reset',[0 1 0 1],5,0,0,1,0.3};
for k=1:size(cases,1)
 name=cases{k,1}; in=Simulink.SimulationInput(m);
 vals=struct('Host_Enable_Schedule',cases{k,2},'Host_Speed_mmps',cases{k,3}, ...
  'Host_Iq_Test_Mode',cases{k,4},'Host_Iq_A',cases{k,5},'Host_PI_Reset_EN',cases{k,6});
 ns=fieldnames(vals);for j=1:numel(ns),in=in.setVariable(ns{j},vals.(ns{j}),'Workspace',m);end
 in=in.setModelParameter('StopTime',num2str(cases{k,7}));o=sim(in);
 assert(all(isfinite([o.position_mm.Data(:);o.speed_mmps.Data(:);o.compare_counts.Data(:)])));
 x=o.position_mm; v=o.speed_mmps;
 cl=logv('Close_EN');pe=logv('Pos_EN');pw=logv('PWM_EN');
 vr=logv('speed_reference'); qr=logv('iq_reference');si=logv('speed_integrator');
 % Disabling PWM acts on the original final vd/vq multipliers.
 vd=logv('vd_applied');vq=logv('vq_applied');
 en=interp1(pw.Time,pw.Data,vd.Time,'previous');
 assert(all(vd.Data(en==0)==0) && all(vq.Data(en==0)==0));
 % Close_Loop_EN removes the external-loop speed command immediately.
 ce=interp1(cl.Time,cl.Data,vr.Time,'previous');
 assert(all(vr.Data(ce==0)==0));
 % Check speed PI clear/reset after the next speed tick.
 for row=1:size(cases{k,2},1)
  if cases{k,2}(row,2)~=0,continue;end
  begin=cases{k,2}(row,1)+0.002; finish=cases{k,7};
  if row<size(cases{k,2},1),finish=cases{k,2}(row+1,1);end
  mask=si.Time>=begin & si.Time<finish;assert(all(si.Data(mask)==0));
  if cases{k,4}==0,mask=qr.Time>=begin & qr.Time<finish;assert(all(qr.Data(mask)==0));end
 end
 switch name
  case 'position'
   mask=x.Time>2.5;assert(max(abs(x.Data(mask)-10))<0.1);
  case 'speed'
   assert(abs(v.Data(end)-5)<0.2);assert(abs(vr.Data(end)-5)<1e-12);
  case {'closed_off','pwm_off','pi_reset'}
   assert(max(abs(x.Data))<1e-9);
  case 'current_only'
   assert(all(abs(qr.Data-0.05)<1e-12));
  case 'switching'
   mask=vr.Time>=0.7 & vr.Time<1.2;assert(all(abs(vr.Data(mask)-5)<1e-12));
   mask=x.Time>3.5;assert(max(abs(x.Data(mask)-10))<0.1);
 end
 % Carriers/counters continue regardless of enable state.
 st=o.speed_tick.Time(logical(o.speed_tick.Data));pt=o.position_tick.Time(logical(o.position_tick.Data));
 assert(max(abs(diff(st)-0.001))<1e-10 && max(abs(diff(pt)-0.01))<1e-10);
 r=struct('case',name,'final_position_mm',x.Data(end),'final_speed_mmps',v.Data(end),'pass',true);
 % PWM-off holds speed and current PI integrators reset after their next ticks.
 for row=1:size(cases{k,2},1)
  if cases{k,2}(row,4)~=0,continue;end
  begin=cases{k,2}(row,1)+0.002; finish=cases{k,7};
  if row<size(cases{k,2},1),finish=cases{k,2}(row+1,1);end
  assert(all(si.Data(si.Time>=begin & si.Time<finish)==0));
  for key={'id_integrator','iq_integrator','ud_pi','uq_pi'}
   q=logv(key{1});mask=q.Time>=begin & q.Time<finish;
   assert(any(mask) && all(q.Data(mask)==0),key{1});
  end
 end
 r.restart_peak_speed_mmps=[];
 if strcmp(name,'switching')
  mask=v.Time>=1 & v.Time<1.2;
  r.restart_peak_speed_mmps=max(abs(v.Data(mask)));
 end
 report{end+1}=r;fprintf('ENABLE_PASS %s\n',jsonencode(r)); %#ok<AGROW>
 if strcmp(name,'switching')
  f=figure('Visible','off','Color','w','Position',[100 100 1100 850]);tiledlayout(4,1);
  nexttile;stairs(cl.Time,cl.Data);hold on;stairs(pe.Time,pe.Data+1.5);stairs(pw.Time,pw.Data+3);grid on;legend('Close','Position + 1.5','PWM + 3');
  nexttile;plot(x.Time,x.Data);ylabel('x (mm)');grid on;
  nexttile;plot(v.Time,v.Data,vr.Time,vr.Data,'--');ylabel('v (mm/s)');grid on;legend('Actual','Reference');
  nexttile;plot(vd.Time,vd.Data,vq.Time,vq.Data);ylabel('Voltage (V)');xlabel('Time (s)');grid on;
  exportgraphics(f,'docs/enable_switching_response.png','Resolution',120);close(f);
 end
end
fid=fopen('docs/enable_validation_results.json','w');fprintf(fid,'%s',jsonencode([report{:}],'PrettyPrint',true));fclose(fid);
fprintf('ENABLE_VALIDATION_PASS\n');
 function ts=logv(name),ts=o.logsout.get(name).Values;end
end
