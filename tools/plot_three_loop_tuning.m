function plot_three_loop_tuning
root=fileparts(fileparts(mfilename('fullpath')));folder=fullfile(root,'docs','three_loop_tuning');
f=figure('Color','w','Position',[80 80 1250 850]);tiledlayout(2,2,'TileSpacing','compact');
for item={'current','speed_step','position_final'}
 d=load(fullfile(folder,[item{1} '.mat']));nexttile;hold on;
 switch item{1}
  case 'current',key='iq';label='iq (A)';
  case 'speed_step',key='v_mmps';label='Speed (mm/s)';
  otherwise,key='x_mm';label='Position (mm)';
 end
 legends=cell(size(d.rows));
 for j=1:numel(d.rows)
  s=d.runs{j}.logsout.get(key).Values;plot(s.Time,s.Data,'LineWidth',1.1);
  legends{j}=d.rows{j}.tag;
 end
 ylabel(label);xlabel('Time (s)');grid on;legend(legends,'Interpreter','none');
 title(strrep(item{1},'_',' '));
end
nexttile;hold on;d=load(fullfile(folder,'validate_final.mat'));
for j=[2 4 6]
 s=d.runs{j}.logsout.get('x_mm').Values;plot(s.Time,s.Data,'LineWidth',1.1);
end
ylabel('Position (mm)');xlabel('Time (s)');grid on;
legend('10 mm','10 mm, load 1 N','PWM off/on');title('Selected gains');
exportgraphics(f,fullfile(folder,'comparison.png'),'Resolution',140);
savefig(f,fullfile(folder,'comparison.fig'));
end
