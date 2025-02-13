function Gene_labels = GC_heatmapTopn(data,cluster_label,H,allgenes,No_exc_cell,No_select_genes,topn,folder)
% This function assign genes to each cluster by SoptSC
%
%   Input:
%      -- data: full gene-cell data matrix
%      -- cluster_label: cluster labels for all cells
%      -- H: non-negative matrix such that W = H*H^T
%      -- No_exc_cell: Gene selection parameter range from [0,No_cells] (No_cells represents
%                   the number of cells), we remove genes that are expressed less than 
%                   No_exc_cell cells and more than (No_cells - No_exc_cell)
%                   cells (Default value: No_exc_cell = 6)
%     --  No_select_genes: maximal number of genes to be ploted
%     --  topn: Number of top markers for each cluster
%     --  folder: folder name where the figures will be saved to
%   
%
%   Output:
%       Gene_labels: gene label information for each gene associated with a specific
%       cluster.
%       -- 1st columns of Gene_labels represents gene indices;
%       -- 2nd column of Gene_labels represents the cluster index that the gene belongs to; 
%       -- 3rd column represent gene score associated with corresponding cluster.

No_cluster = max(cluster_label);
No_cells_inC = [];
for i = 1:No_cluster
    No_cells_inC = [No_cells_inC; length(find(cluster_label==i))];
end
xtkval = cumsum(No_cells_inC);
xtkval1 = zeros(size(xtkval));
for i = 1:No_cluster
    if i==1
        xtkval1(i) = 0.5.*No_cells_inC(i);
    else
        xtkval1(i) = xtkval(i-1) + 0.5.*No_cells_inC(i);
    end
end
    
% xtkval = xtkval./max(xtkval);
% xtkval = No_cluster.*xtkval;

[~,gene_idx] = Data_selection(data,No_exc_cell,No_select_genes);

data = data(gene_idx,:);

NC = max(cluster_label);
m = size(data,1);
Gene_labels = zeros(m,3);

Gene_labels(:,1) = gene_idx;

%% data normalization
for i = 1:size(data,2)
    data(:,i) = data(:,i)./norm(data(:,i),1);
end


%%
G_latent = data*H;

[Gene_value,Gene_label] = max(G_latent,[],2);

Gene_labels(:,2) = Gene_label;
Gene_labels(:,3) = Gene_value;


OGI = [];
OGV = [];

CGI = [];
topn1 = topn;
gene_id = [];
cell_id = [];

G_table = [];
for i = 1:NC
    % order genes within each cluster
    Z = find(Gene_label==i);
    Z1 = Gene_value(Z);
    [Z1V,I] = sort(Z1,'descend');
    
    if topn1 > length(Z)
        topn1 = length(Z);
    end
    
    gene_id = [gene_id; i.*ones(topn1,1)];
    cell_id = [cell_id; i.*ones(length(find(cluster_label==i)),1)];
    Z2 = Z(I(1:topn1));
    OGI = [OGI; Z2];
    OGV = [OGV; Z1V(1:topn1)];
    
    ICS = cell(topn,1);
    ICS(1:length(Z2)) = allgenes(gene_idx(Z2));
    G_table = [G_table, table(ICS, 'VariableNames',cellstr(['Markers_C' num2str(i)]))];
    Y = find(cluster_label==i);
    CGI = [CGI; Y];
    topn1 = topn;
end
display(G_table);

%% data normalization and zscroe
% kk = 1 row; kk = 2 column
figure;
idata = data(OGI,CGI);
kk = 2;
center = mean(idata,kk);
scale = std(idata, 0,kk);

tscale = scale;
%=Check for zeros and set them to 1 so not to scale them.
scale(tscale == 0) = 1;
%== Center and scale the data
idata = bsxfun(@minus, idata, center);
sdata = bsxfun(@rdivide, idata, scale);

thresh = 3;
colormap redbluecmap;
clims = [-thresh thresh];
imagesc(sdata,clims);
set(gca,'xtick',[]);
set(gca,'ytick',[]);


lgd = cell(1,No_cluster);
for i = 1:No_cluster
    if i<10
        vv = 'CC';
        vv(2:2) = num2str(i);
        lgd{i} = vv;
    else
        vv = 'CCC';
        vv(2:3) = num2str(i);
        lgd{i} = vv;
    end
end

if length(OGI) <= 200
    yticks(1:length(OGI));
    yticklabels(allgenes(gene_idx(OGI)));
    xticks(xtkval1);
    xticklabels(lgd);
end
cb = colorbar;
ax = gca;
axpos = ax.Position;
cpos = cb.Position;
cpos(3) = 0.5*cpos(3);
cb.Position = cpos;
ax.Position = axpos;

print([folder '\GChtmp_' num2str(topn)],'-dpdf','-r300','-fillpage'); 


