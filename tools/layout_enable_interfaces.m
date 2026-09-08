function layout_enable_interfaces
% Layout only the enable interfaces and their directly connected blocks.
% Original position/speed subsystem contents are intentionally untouched.
m='PMLSM_ThreeLoop_Simple';
r(523,[30 60 240 580]);r(505,[500 60 720 660]);r(771,[1050 100 1260 550]);
r(786,[-30 300 -5 325]);
r(785,[545 -35 600 -5]);r(503,[840 -70 845 5]);r(504,[900 -50 1050 -20]);
aout(523,[926 939 941 1243 1245 1247 1249 1251 1253 1255 1257],1:11,265);
ain(505,[921 922 493 495 497 499 502 1244 1246 1250 1252 1254 1256 1258],2:15,380);
aout(505,[928 930 932 934],4:7,770);
ain(771,[500 940 923 924 925 1248],4:9,940);aout(771,936,3,1280);
% Control task: original loops, with routing outside their boundaries.
r(1109,[260 240 400 360]);r(1122,[800 240 950 410]);
r(991,[480 490 690 830]);r(546,[1270 235 1490 575]);r(740,[460 50 630 130]);
port(767,100,55);ain(1109,[508 509],1:2,70);
port(510,720,380);ain(546,511:515,1:5,1160);
aout(546,516:520,1:5,1570);port(521,760,80);port(522,760,130);
r(1233,[70 335 100 365]);
ain(991,[1041 1040 1042 1043 1044 1045],3:8,330);
port(1046,65,650);
r(1234,[30 760 165 790]);r(1236,[30 810 165 840]);r(1238,[30 860 165 890]);
r(1235,[160 675 290 705]);r(1237,[160 625 290 655]);r(1239,[160 725 290 755]);
r(943,[755 645 835 667]);ain(546,944,6,1160);
aout(1109,1259,1,430);aout(1122,1261,1,1000);
ain(991,[1262 1260],1:2,350);aout(991,[1265 1263],[1 3],755);
ain(1122,1264,1,690);ain(546,[1266 1268],7:8,1160);
r(1267,[170 565 250 587]);
% PWM output multiplication copied from the original average inverter.
r(790,[660 80 850 420]);r(1241,[985 165 1020 200]);r(1242,[985 325 1020 360]);
port(1240,780,500);port(782,1100,180);port(783,1100,340);port(784,1100,600);
r(906,[455 570 460 630]);
% Newly added FOC reference/reset ports; retain completed FOC layout.
ain(566,1107,1,660);port(1108,60,570);
% Restore default dimensions for newly introduced/replaced port blocks only.
for sid=[1040:1046 1087:1090 1099 1103 1107 1108 1240]
 q=get_param(p(sid),'Position');set_param(p(sid),'Position',[q(1:2) q(1)+30 q(2)+14]);
end
for scope={m,p(505),p(771)}
 bs=find_system(scope{1},'SearchDepth',1,'RegExp','on','BlockType','^(From|Goto)$');
 for j=1:numel(bs),q=get_param(bs{j},'Position');y=mean(q([2 4]));set_param(bs{j},'Position',[q(1) y-11 q(1)+85 y+11],'ShowName','off');end
 ls=find_system(scope{1},'FindAll','on','SearchDepth',1,'Type','line');Simulink.BlockDiagram.routeLine(ls);
end
save_system(m);print(['-s' m],'-dpng','-r100','docs/three_loop_model.png');
print(['-s' p(505)],'-dpng','-r100','docs/three_loop_control_task.png');
print(['-s' p(1109)],'-dpng','-r100','docs/original_position_loop.png');
print(['-s' p(1122)],'-dpng','-r100','docs/original_speed_loop.png');
open_system(m);set_param(m,'ZoomFactor','FitSystem');
 function s=p(id),s=Simulink.ID.getFullName(sprintf('%s:%d',m,id));end
 function r(id,q),set_param(p(id),'Position',q);end
 function port(id,x,y),q=get_param(p(id),'Position');sz=q(3:4)-q(1:2);r(id,[x y-sz(2)/2 x+sz(1) y+sz(2)/2]);end
 function ain(id,ids,nums,x),ph=get_param(p(id),'PortHandles');for j=1:numel(ids),xy=get_param(ph.Inport(nums(j)),'Position');port(ids(j),x,xy(2));end;end
 function aout(id,ids,nums,x),ph=get_param(p(id),'PortHandles');for j=1:numel(ids),xy=get_param(ph.Outport(nums(j)),'Position');port(ids(j),x,xy(2));end;end
end
