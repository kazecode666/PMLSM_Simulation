function audit_original_loops
% Compare every copied internal block, parameter expression and position.
src='PMLSM_ControlCore_Block'; dst='PMLSM_ThreeLoop_Simple'; results={};
for pair=[592 1109;605 1122]'
 a=Simulink.ID.getFullName(sprintf('%s:%d',src,pair(1)));
 b=Simulink.ID.getFullName(sprintf('%s:%d',dst,pair(2)));
 aa=find_system(a,'LookUnderMasks','all','FollowLinks','off','Type','Block');
 bb=find_system(b,'LookUnderMasks','all','FollowLinks','off','Type','Block');
 assert(numel(aa)==numel(bb),'Internal block count changed');
 mismatches={};checked=0;
 for k=2:numel(aa)
  rel=extractAfter(aa{k},length(a)); ix=find(strcmp(bb,[b char(rel)]),1);
  assert(~isempty(ix)); target=bb{ix};
  dp=get_param(aa{k},'DialogParameters');pp={};if isstruct(dp),pp=fieldnames(dp);end
  pp=[pp;{'BlockType';'Position';'Orientation';'Commented'}];
  for j=1:numel(pp)
   x=get_param(aa{k},pp{j});y=get_param(target,pp{j});checked=checked+1;
   if ~isequaln(x,y),mismatches{end+1}=[char(rel) ':' pp{j}];end %#ok<AGROW>
  end
 end
 assert(isempty(mismatches),'Copied loop parameters/layout differ');
 % Compare line geometry inside all nested scopes, excluding signal logging metadata.
 la=find_system(a,'FindAll','on','Type','line');lb=find_system(b,'FindAll','on','Type','line');
 assert(numel(la)==numel(lb),'Line count differs');
 shapeA=cell(numel(la),1);shapeB=cell(numel(lb),1);
 for k=1:numel(la),shapeA{k}=mat2str(get_param(la(k),'Points'));end
 for k=1:numel(lb),shapeB{k}=mat2str(get_param(lb(k),'Points'));end
 assert(isequal(sort(shapeA),sort(shapeB)),'Original internal line routes differ');
 r=struct('source',a,'copy',b,'internal_blocks',numel(aa)-1,'checked_properties',checked, ...
  'line_segments',numel(la),'internal_layout_and_parameters_identical',true);
 results{end+1}=r;fprintf('COPY_AUDIT_PASS %s\n',jsonencode(r)); %#ok<AGROW>
end
fid=fopen('docs/original_loop_copy_audit.json','w');fprintf(fid,'%s',jsonencode([results{:}],'PrettyPrint',true));fclose(fid);
end
