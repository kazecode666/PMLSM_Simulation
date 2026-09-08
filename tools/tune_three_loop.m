function tune_three_loop(stage,xi,h,separation)
% Runs candidates using temporary SimulationInput overrides; no model edits.
if nargin<2,xi=1;end
if nargin<3,h=10;end
if nargin<4,separation=20;end
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);cd(root);
m='PMLSM_ThreeLoop_Simple';open_system(m);w=get_param(m,'ModelWorkspace');
dirout=fullfile(root,'docs','three_loop_tuning');if ~exist(dirout,'dir'),mkdir(dirout);end
rows={};runs={};
switch stage
 case 'current', list=[1 .85 1/sqrt(2)];
 case {'speed','speed_step'}, list=[10 5 3];
 case {'position','position_final'}, list=[40 20 10];
 case 'reset_check', list=[.2 0];
 case 'validate',list=1:8;
 case 'validate_final',list=1:12;
 otherwise,error('Unknown stage');
end
for a=list
 xx=xi;hh=h;ss=separation;
 if strcmp(stage,'current'),xx=a;end
 if startsWith(stage,'speed'),hh=a;end
 if startsWith(stage,'position'),ss=a;end
 g=design_PMLSM_three_loop(w.getVariable('PMLSM_Rs_ohm'),w.getVariable('PMLSM_Lq_H'), ...
 w.getVariable('PMLSM_M_kg'),w.getVariable('PMLSM_Kf_peak_N_per_Apeak'), ...
 w.getVariable('Ts_ACR'),w.getVariable('Ts_ASR'),w.getVariable('Ts_POS'),xx,hh,ss);
 vals=g; keep={'Kp_ACR','Ki_ACR','Kaw_d','Kaw_q','Kp_ASR','Ki_ASR','Kaw_s','Kp_pos'};
 vals=rmfield(vals,setdiff(fieldnames(vals),keep));
 vals.Host_Target_mm=10;vals.Host_Start_s=.1;vals.Host_Load_N=0;
 vals.Host_Enable_Schedule=[0 1 1 1];vals.Host_Speed_mmps=0;
 vals.Host_Iq_Test_Mode=0;vals.Host_Iq_A=0;vals.Host_Id_A=0;vals.Host_PI_Reset_EN=0;
 vals.v_ref_zero_eps=.2; % Preserve the pre-tuning comparison configuration.
 if endsWith(stage,'final'),vals.v_ref_zero_eps=0;end
 stop=3;kind='position';tag=sprintf('%s_%g',stage,a);
 if strcmp(stage,'current')
  kind='current';stop=.04;vals.Host_Enable_Schedule=[0 0 0 0;.01 0 0 1];
  vals.Host_Iq_Test_Mode=1;vals.Host_Iq_A=.2;
 elseif startsWith(stage,'speed')
  kind='speed';stop=.8;vals.Host_Enable_Schedule=[0 1 0 1];vals.Host_Speed_mmps=10;
  if strcmp(stage,'speed_step')
   stop=.15;vals.v_ref_set_step_up=20;vals.v_ref_set_step_dn=20;
  end
 elseif strcmp(stage,'reset_check')
  vals.Host_Load_N=1;vals.v_ref_zero_eps=a;
 elseif startsWith(stage,'validate')
  switch a
   case 1,tag='position_1mm';vals.Host_Target_mm=1;
   case 2,tag='position_10mm';
   case 3,tag='position_minus10mm';vals.Host_Target_mm=-10;
   case 4,tag='position_load_1N';vals.Host_Load_N=1;
   case 5,tag='speed_load_1N';kind='speed';stop=1;vals.Host_Enable_Schedule=[0 1 0 1];vals.Host_Speed_mmps=10;vals.Host_Load_N=1;
   case 6,tag='pwm_restart';stop=4;vals.Host_Enable_Schedule=[0 1 1 1;.8 1 1 0;1 1 1 1];
   case 7,tag='negative_current';kind='current';stop=.04;vals.Host_Enable_Schedule=[0 0 0 0;.01 0 0 1];vals.Host_Iq_Test_Mode=1;vals.Host_Iq_A=-.2;
   case 8,tag='small_current';kind='current';stop=.04;vals.Host_Enable_Schedule=[0 0 0 0;.01 0 0 1];vals.Host_Iq_Test_Mode=1;vals.Host_Iq_A=.05;
   case 9,tag='d_current';kind='current_d';stop=.04;vals.Host_Enable_Schedule=[0 0 0 0;.01 0 0 1];vals.Host_Iq_Test_Mode=1;vals.Host_Id_A=.2;
   case 10,tag='mass_plus20pct';vals.PMLSM_M_kg=1.2*w.getVariable('PMLSM_M_kg');
   case 11,tag='inductance_minus20pct';vals.PMLSM_Ld_H=.8*w.getVariable('PMLSM_Ld_H');vals.PMLSM_Lq_H=.8*w.getVariable('PMLSM_Lq_H');
   case 12,tag='position_load_2N';vals.Host_Load_N=2;
  end
 end
 in=Simulink.SimulationInput(m);ns=fieldnames(vals);
 for k=1:numel(ns),in=in.setVariable(ns{k},vals.(ns{k}),'Workspace',m);end
 in=in.setModelParameter('StopTime',num2str(stop));o=sim(in);
 q=metrics(o,kind,vals,stop);q.tag=tag;q.gains=g;q.overrides=vals;
 rows{end+1}=q;runs{end+1}=o; %#ok<AGROW>
 fprintf('TUNE %s\n',jsonencode(q));
 fid=fopen(fullfile(dirout,[stage '.json']),'w');fprintf(fid,'%s',jsonencode(rows,'PrettyPrint',true));fclose(fid);
 save(fullfile(dirout,[stage '.mat']),'rows','runs');
end
fprintf('TUNING_STAGE_COMPLETE %s\n',stage);
end
function r=metrics(o,kind,vals,stop)
l=o.logsout;expected={'x_ref_mm','x_mm','ia','ib','ic','iq_ref','iq','id_ref','id','ud','uq','v_mmps','v_ref'};
assert(isequal(sort(l.getElementNames),sort(expected(:))));
for k=1:numel(expected),d=l.get(expected{k}).Values.Data;assert(all(isfinite(d(:))));end
x=l.get('x_mm').Values;v=l.get('v_mmps').Values;iq=l.get('iq').Values;id=l.get('id').Values;
r=struct('kind',kind,'final_x_mm',x.Data(end),'final_v_mmps',v.Data(end), ...
'peak_iq_A',max(abs(iq.Data)),'peak_id_A',max(abs(id.Data)));
switch kind
 case 'current', sig=iq;ref=vals.Host_Iq_A;start=.01;tol=max(.02*abs(ref),.002);window=.01;
 case 'current_d',sig=id;ref=vals.Host_Id_A;start=.01;tol=max(.02*abs(ref),.002);window=.01;
 case 'speed',sig=v;ref=vals.Host_Speed_mmps;start=0;tol=.2;window=.2;
 otherwise,sig=x;ref=vals.Host_Target_mm;start=.1;tol=.05;window=.5;
end
window=min(window,stop/3);mask=sig.Time>=stop-window;e=sig.Data-ref;active=sig.Time>=start;
r.mean_error=mean(e(mask));r.rms_error=sqrt(mean(e(mask).^2));r.tail_max_error=max(abs(e(mask)));
r.overshoot=max(0,max(sign(ref)*e(active)));r.tolerance=tol;
bad=find(active & abs(e)>tol,1,'last');
if isempty(bad),r.settling_s=0;elseif bad==numel(e),r.settling_s=[];else,r.settling_s=sig.Time(bad+1)-start;end
r.pass_tail=r.tail_max_error<=tol;
if startsWith(kind,'current'),idx=find(sig.Time>=start & sign(ref)*sig.Data>=.9*abs(ref),1);if isempty(idx),r.t90_s=[];else,r.t90_s=sig.Time(idx)-start;end;end
end
