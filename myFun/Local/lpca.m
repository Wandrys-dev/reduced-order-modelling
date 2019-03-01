function [eigvec, n_eig, gamma, u_scores, eigenvalues, centroids, eps_rec] = lpca(nz_X_k, n_eigs, cent_crit, scal_crit, is_parallel, is_cpca, idx, cpca_options)
%% Inputs
if ~exist('cent_crit', 'var') || isempty(cent_crit)
    cent_crit = 1;
end
if ~exist('scal_crit', 'var') || isempty(scal_crit)
    scal_crit = 0;
end
if ~exist('is_parallel', 'var') || isempty(is_parallel)
    is_parallel = false;
end
if ~exist('is_cpca', 'var') || isempty(is_cpca)
    is_cpca = false;
end
if ~exist('idx', 'var') || isempty(idx)
    idx = [];
end
if nargin < 8
    cpca_options = [];
end
% Check CPCA
if is_cpca
    is_parallel = false;
    cpca_options.idx = idx;
end
if is_cpca && isempty(idx)
    error('For Local Constrained PCA, you must provide IDX.');
end
%% Main
a_tol = 1e-16;
% Number of clusters
k = length(nz_X_k);
n_vars = size(nz_X_k{1}, 2);
% Initialization of cell arrays
eigvec = cell(k, 1);
u_scores = cell(k, 1);
n_eig = zeros(k, 1);
gamma = zeros(k, n_vars);
eigenvalues = cell(k, 1);
centroids = zeros(k, n_vars);
% Apply PCA in each cluster
sq_rec_err = zeros(length(idx), 1);
eps_rec = [];
for j = 1 : k
    % Center and scale, then do PCA
    [X, centroids(j,:)] = center(nz_X_k{j}, cent_crit);
    [X, gamma(j,:)] = scale(X, nz_X_k{j}, scal_crit);
    [modes, scores, eigenvalues{j}] = pca(X, 'Centered', false, 'Algorithm', 'svd'); 
    % Check n_eigs does not exceed the found number of modes
    n_modes = n_eigs;
    n_scores = n_eigs;
    if n_eigs > size(modes, 2)
        n_modes = size(modes, 2);
        n_scores = size(modes, 2);
    end
    % Outputs (and gamma)
    n_eig(j) = n_eigs;
    eigvec{j} = modes(:, 1:n_modes);
    u_scores{j} = scores(:, 1:n_scores);
    % Rec err
    if ~isempty(idx)
        try
            D = spdiags(gamma(j,:) + a_tol, 0, n_vars, n_vars);
        catch
           try
               D = diag(gamma(j,:) + a_tol);
           catch
               D = 1;
           end
        end
        C_mat = repmat(centroids(j,:), size(X, 1), 1);
        rec_err_os = (nz_X_k{j} - C_mat) - (nz_X_k{j} - C_mat) * D^-1 * eigvec{j} * eigvec{j}' * D; % Get error
        sq_rec_err(idx == j, :) = sum(rec_err_os.^2, 2);
    end
end
if ~isempty(idx)
    eps_rec = mean(sq_rec_err);
end
end



