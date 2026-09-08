function out = run_PMLSM_ThreeLoop_Simple(target_mm)
% Run the independent three-loop model. Example: out=run_PMLSM_ThreeLoop_Simple(10)
if nargin<1, target_mm=10; end
validateattributes(target_mm,{'numeric'},{'scalar','real','finite'});
root=fileparts(mfilename('fullpath'));
addpath(root);
model='PMLSM_ThreeLoop_Simple';
if bdIsLoaded(model)
    assert(strcmpi(get_param(model,'FileName'),fullfile(root,[model '.slx'])), ...
        'A different copy of this model is already loaded.');
end
open_system(fullfile(root,[model '.slx']));
in=Simulink.SimulationInput(model);
in=in.setVariable('Host_Target_mm',target_mm,'Workspace',model);
w=get_param(model,'ModelWorkspace');reload(w);
[~,~,T]=pmlsm_scurve_profile(0,target_mm,w.getVariable('Host_Traj_Vmax'), ...
 w.getVariable('Host_Traj_Amax'),w.getVariable('Host_Traj_Jmax'), ...
 w.getVariable('Host_Speed_Ramp_s'));
in=in.setModelParameter('StopTime',num2str(w.getVariable('Host_Start_s')+T+1.5));
out=sim(in);
figure('Name','PMLSM simple three-loop response','Color','w','Position',[100 100 1200 850]);
tiledlayout(3,2,'TileSpacing','compact');
plot_group({'x_ref_mm','x_mm'},'Position (mm)');
plot_group({'v_ref','v_mmps'},'Speed (mm/s)');
plot_group({'ia','ib','ic'},'Phase current (A)');
plot_group({'ud','uq'},'Applied voltage (V)');
plot_group({'iq_ref','iq'},'q current (A)');
plot_group({'id_ref','id'},'d current (A)');
x=out.logsout.get('x_mm').Values;
fprintf('Target %.6f mm; final %.9f mm; error %.9f mm\n',target_mm,x.Data(end),target_mm-x.Data(end));
    function plot_group(names,label)
        nexttile;hold on;
        for j=1:numel(names)
            signal=out.logsout.get(names{j}).Values;
            style='-';if contains(names{j},'ref'),style='--';end
            plot(signal.Time,signal.Data,style,'LineWidth',1.1);
        end
        ylabel(label);xlabel('Time (s)');
        legend(names,'Interpreter','none');grid on;
    end
end
