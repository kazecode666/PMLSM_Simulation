function validate_three_loop
% Called in a fresh batch MATLAB process, from an isolated copied folder.
model='PMLSM_ThreeLoop_Simple';
evalin('base','clear variables');
load_system(model);
[files,missing]=dependencies.fileDependencyAnalysis(model,'AnalyzeToolboxFiles',false);
assert(isempty(missing));
for k=1:numel(files)
    assert(startsWith(lower(files{k}),lower(pwd)),'External user dependency: %s',files{k});
end
assert(isempty(find_system(model,'BlockType','ModelReference')));
% Three local command stores carry the enable/reset commands.
assert(numel(find_system(model,'BlockType','DataStoreMemory'))==3);
assert(numel(find_system(model,'BlockType','TriggerPort'))==3);
inverter=Simulink.ID.getFullName([model ':771']);
assert(isempty(find_system(inverter,'BlockType','Switch')));
assert(isempty(find_system(inverter,'BlockType','MultiPortSwitch')));
assert(numel(find_system(inverter,'BlockType','UnitDelay'))==3);
targets=[0 1 10 -10];
results=cell(1,numel(targets));
for k=1:numel(targets)
    in=Simulink.SimulationInput(model);
    in=in.setVariable('Host_Target_mm',targets(k),'Workspace',model);
    in=in.setModelParameter('StopTime','3');
    out=sim(in);
    x=out.position_mm.Data;v=out.speed_mmps.Data;iq=out.iq_A.Data;
    id=out.id_A.Data;counts=out.compare_counts.Data;
    assert(all(isfinite([x(:);v(:);iq(:);id(:);counts(:)])));
    % Position deadband and PI gains are retained; stop-output gating is removed.
    assert(abs(x(end)-targets(k))<0.1,'Position envelope failed');
    assert(abs(v(end))<0.6,'Speed envelope failed');
    assert(min(counts(:))>=-1e-6 && max(counts(:))<=10000+1e-6,'Compare count range failed');
    assert(out.reference_mm.Data(end)==targets(k),'Host target override failed');
    % Original /10 and /100 counter pulses inside the 100 us task.
    st=out.speed_tick.Time(logical(out.speed_tick.Data));
    pt=out.position_tick.Time(logical(out.position_tick.Data));
    assert(numel(st)==3000 && max(abs(diff(st)-1e-3))<1e-10);
    assert(numel(pt)==300 && max(abs(diff(pt)-1e-2))<1e-10);
    assert(abs(st(1)-0.0009)<1e-10 && abs(pt(1)-0.0099)<1e-10);
    % The three compare values are physically applied 50 us after calculation.
    applied=out.applied_counts.Data;
    t=out.applied_counts.Time;
    expected=5000*ones(size(applied));
    index=floor((t(2:end)-50e-6+1e-10)/1e-4)+1;
    expected(2:end,:)=counts(index,:);
    pwm_error=max(abs(applied-expected),[],'all');
    assert(pwm_error<1e-8,'Actual PWM update is not delayed by 50 us');
    % Check the retained original per-phase dead-time voltage equation.
    ia=out.logsout.get('ia_raw').Values.Data;
    ib=out.logsout.get('ib_raw').Values.Data;
    ic=out.logsout.get('ic_raw').Values.Data;
    theta=out.logsout.get('theta_actual').Values.Data;
    currents=[ia ib ic];
    polarity=sign(currents).*(abs(currents)>1e-4);
    phase=48*min(1,max(0,1-applied/10000-0.01*polarity));
    alpha=(2*phase(:,1)-phase(:,2)-phase(:,3))/3;
    beta=(phase(:,2)-phase(:,3))/sqrt(3);
    vd_expected=alpha.*cos(theta)+beta.*sin(theta);
    vq_expected=-alpha.*sin(theta)+beta.*cos(theta);
    deadtime_error=max(abs([vd_expected-out.logsout.get('vd_applied').Values.Data; ...
        vq_expected-out.logsout.get('vq_applied').Values.Data]));
    assert(deadtime_error<1e-10,'Dead-time voltage equation mismatch');
    r=struct('target_mm',targets(k),'final_mm',x(end),'error_mm',targets(k)-x(end), ...
        'final_speed_mmps',v(end),'peak_iq_A',max(abs(iq)),'peak_id_A',max(abs(id)), ...
        'min_count',min(counts(:)),'max_count',max(counts(:)), ...
        'speed_executions',numel(st),'position_executions',numel(pt), ...
        'pwm_delay_error_counts',pwm_error,'deadtime_equation_error_V',deadtime_error);
    results{k}=r;
    fprintf('PASS %s\n',jsonencode(r));
    if targets(k)==10
        save('positive_10mm.mat','out');
        fig=figure('Visible','off','Color','w','Position',[100 100 1000 750]);
        tiledlayout(3,1);
        nexttile;plot(out.reference_mm.Time,out.reference_mm.Data,'--',out.position_mm.Time,x,'LineWidth',1.4);grid on;ylabel('Position (mm)');legend('Reference','Actual');
        nexttile;plot(out.speed_mmps.Time,v,'LineWidth',1.4);grid on;ylabel('Speed (mm/s)');
        nexttile;plot(out.iq_A.Time,iq,out.id_A.Time,id,'LineWidth',1.2);grid on;ylabel('Current (A)');xlabel('Time (s)');legend('iq','id');
        exportgraphics(fig,'position_response.png','Resolution',140);close(fig);
    end
end
report=struct('revision','pwm_pi_reset_cleanup_20260908','release',version,'isolated_directory',pwd);
report.results=[results{:}];
fid=fopen('validation_results.json','w');fprintf(fid,'%s',jsonencode(report,'PrettyPrint',true));fclose(fid);
fprintf('THREE_LOOP_VALIDATION_PASS\n');
bdclose(model);
end
