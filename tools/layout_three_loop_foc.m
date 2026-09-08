function layout_three_loop_foc
% Scope-limited manual FOC layout; never rearrange other subsystems.
m='PMLSM_ThreeLoop_Simple'; root=p(546);
r(553,[170 150 280 260]); r(617,[370 110 490 320]);
r(566,[800 70 930 280]); r(591,[800 390 930 600]);
r(698,[1100 180 1260 460]); r(590,[1460 125 1570 290]);
r(618,[1690 120 1810 300]);
ain(553,547:549,1:3,60);
ain(617,954,3,270); aout(617,[945 949],1:2,530);
ain(566,[1107 946 950 957 960 1270],1:6,660);
ain(591,[552 947 951 958 962 1271],1:6,660);
port(1108,60,570);r(1269,[160 559 230 581]);
ain(590,955,3,1360);
aout(698,[959 961 696],3:5,1300);
aout(618,[735 736 737 697],1:4,1870);
% Angle/speed distribution and measured dq output bank.
port(550,60,430); port(551,60,500);
r(953,[160 419 230 441]); r(956,[160 489 230 511]);
r(948,[360 419 430 441]); port(738,530,430);
r(952,[360 489 430 511]); port(739,530,500);
bs=find_system(root,'SearchDepth',1,'RegExp','on','BlockType','^(From|Goto)$');
for k=1:numel(bs)
 pos=get_param(bs{k},'Position'); y=mean(pos([2 4]));
 set_param(bs{k},'Position',[pos(1) y-11 pos(1)+70 y+11],'ShowName','off');
end
lines=find_system(root,'FindAll','on','SearchDepth',1,'Type','line');
Simulink.BlockDiagram.routeLine(lines);
save_system(m); print(['-s' root],'-dpng','-r120','docs/three_loop_foc.png');
open_system(root);set_param(root,'ZoomFactor','FitSystem');
 function v=p(s),v=Simulink.ID.getFullName(sprintf('%s:%d',m,s));end
 function r(s,pos)
  b=p(s); old=get_param(b,'Position');
  if ismember(get_param(b,'BlockType'),{'Inport','Outport'})
   pos=[pos(1:2),pos(1:2)+old(3:4)-old(1:2)];
  end
  set_param(b,'Position',pos);
 end
 function port(s,x,y)
  b=get_param(p(s),'Position'); sz=b(3:4)-b(1:2);
  r(s,[x y-sz(2)/2 x+sz(1) y+sz(2)/2]);
 end
 function ain(s,ids,nums,x)
  ph=get_param(p(s),'PortHandles');
  for j=1:numel(ids), xy=get_param(ph.Inport(nums(j)),'Position');port(ids(j),x,xy(2));end
 end
 function aout(s,ids,nums,x)
  ph=get_param(p(s),'PortHandles');
  for j=1:numel(ids), xy=get_param(ph.Outport(nums(j)),'Position');port(ids(j),x,xy(2));end
 end
end
