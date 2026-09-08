function restore_cleanup_unrelated_routes
% Restore unchanged root signal geometry from the pre-edit saved model.
m='PMLSM_ThreeLoop_Simple';
base='PMLSM_Cleanup_Layout_Baseline';
file=fullfile(tempdir,[base '.slx']);
copyfile(fullfile(pwd,[m '.slx']),file);
load_system(file);
c=find_system(m,'SearchDepth',1,'FindAll','on','Type','line');
b=find_system(base,'SearchDepth',1,'FindAll','on','Type','line');
count=0;
for k=1:numel(c)
 if get_param(c(k),'LineParent')~=-1,continue;end
 key=linekey(c(k));
 for j=1:numel(b)
  if get_param(b(j),'LineParent')==-1 && strcmp(key,linekey(b(j)))
   copytree(c(k),b(j));count=count+1;break;
  end
 end
end
close_system(base,0);
fprintf('Restored %d unchanged root signal trees.\n',count);
end
function key=linekey(h)
src=get_param(h,'SrcPortHandle');
if src==-1,s='branch';else,s=portkey(src);end
key=[s '>' strjoin(sort(leaves(h)),',')];
end
function k=portkey(h)
p=get_param(h,'Parent');
k=[get_param(p,'SID') ':' get_param(h,'PortType') ':' num2str(get_param(h,'PortNumber'))];
end
function d=leaves(h)
d={};ports=get_param(h,'DstPortHandle');
for p=ports(:)',if p~=-1,d{end+1}=portkey(p);end;end
children=get_param(h,'LineChildren');
for x=children(:)',d=[d leaves(x)];end
end
function copytree(c,b)
set_param(c,'Points',get_param(b,'Points'));
cc=get_param(c,'LineChildren');bb=get_param(b,'LineChildren');
for x=cc(:)'
 for y=bb(:)'
  if strcmp(linekey(x),linekey(y)),copytree(x,y);break;end
 end
end
end
