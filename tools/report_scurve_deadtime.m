function report_scurve_deadtime(baseline, planned, zeroDead)
% Compare identical planned trajectories, changing only dead-time parameters.
root=fileparts(fileparts(mfilename('fullpath')));
outdir=fullfile(root,'docs','scurve');if ~exist(outdir,'dir'),mkdir(outdir);end
r=struct;
r.windows_s=[4 5;11.5 12];
names={'id','iq'};runs={planned,zeroDead};
for k=1:2
 for j=1:2
  for z=1:2
   s=runs{k}.logsout.get(names{j}).Values;
   d=s.Data(s.Time>=r.windows_s(z,1)&s.Time<=r.windows_s(z,2));
   r.current(k,j,z).peak_to_peak_A=max(d)-min(d);
   r.current(k,j,z).std_A=std(d);
  end
 end
end
r.current_dimensions='deadtime [1us,0], axis [id,iq], window [moving,settled]';
x=planned.logsout.get('x_mm').Values;v=planned.logsout.get('v_ref').Values;
r.final_position_mm=x.Data(end);r.peak_speed_reference_mmps=max(abs(v.Data));
r.max_velocity_reference_increment_mmps=max(abs(diff(v.Data)));
for k=1:2
 o={baseline,planned};q=o{k}.logsout.get('iq_ref').Values;
 r.peak_iq_reference_A(k)=max(abs(q.Data));
end
fid=fopen(fullfile(outdir,'validation.json'),'w');fprintf(fid,'%s',jsonencode(r,'PrettyPrint',true));fclose(fid);
save(fullfile(outdir,'comparison.mat'),'baseline','planned','zeroDead','r');
f=figure('Visible','off','Color','w','Position',[100 100 1200 850]);
tiledlayout(3,2,'TileSpacing','compact');
for group={{'x_ref_mm','x_mm'},{'v_ref','v_mmps'}}
 nexttile;hold on;for q=group{1},s=planned.logsout.get(q{1}).Values;plot(s.Time,s.Data);end
 legend(group{1},'Interpreter','none');grid on;xlabel('Time (s)');
end
for j=1:2
 for z=1:2
  nexttile;hold on;
  for k=1:2
   s=runs{k}.logsout.get(names{j}).Values;
   mask=s.Time>=r.windows_s(z,1)&s.Time<=r.windows_s(z,1)+.01;
   plot(s.Time(mask),s.Data(mask));
  end
  ylabel([names{j} ' (A)']);xlabel('Time (s)');grid on;
  legend('Dead time 1 us','Dead time 0');
 end
end
exportgraphics(f,fullfile(outdir,'comparison.png'),'Resolution',140);close(f);
disp(jsonencode(r,'PrettyPrint',true));
end
