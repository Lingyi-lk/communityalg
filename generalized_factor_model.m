function [C,Y,P] = generalized_factor_model(ci,T,eta,mu)
% FACTOR_MODEL Computes a benchmark correlation matrix with
% controllable parameters for the local noise and market mode noise
% See MacMahon, Garlaschelli, Community detection for correlation matrices,
% PhysRev X,5,021006. Section IV, D "Benchmarking our methods"
% Parameters:
% membership: the membership vector to generate the correlation matrix
% T: the number of time samples on which the correlation are estimated
% eta: the local noise parameter
% mu: the market mode parameter
% Output:
% C: the correlation matrix as computed by corrcoef
% Y: The TxN timeseries vector, standardized by zscore, for further
% visualization and inspection.
% P: The P-values of the correlations.
N=length(ci);

% It's important that the number of time samples is greater than the number
% of nodes, otherwise this method produces communities with external
% positive correlation as a by-product
if T<N
    warning('This benchmark is not valid as curse of dimensionality is not respected, See MacMahon Garlaschelli, PhysRevX 2015');
end


% Fill the identical observations in the maximally correlated subsets
cpos=ci;
cmin=ci;
cpos(ci>0) = ci(ci>0);    cpos(ci<0)=0;
cmin(ci<0) = ci(ci<0);    cmin(ci>0)=0;

if length(unique(cpos)) < length(unique(cmin))
    error('Not enough anticorrelated series to generate a valid benchmark');
end

% Initialize the observations vector a TxN matrix of NaNs
Y=nan(T,N);


% Set random indipendent on comm 0
Y(:,ci==0) = randn(T,sum(ci==0));

all_comms = setdiff(unique(cpos(:))',0);
Ypos = randn(T,length(all_comms));

l=1;
for c=setdiff(unique(cpos(:))',0)
    Y(:,ci==c) = repmat(Ypos(:,l),[1,sum(ci==c)]);
    l=l+1;
end

l=1;
for c=setdiff(unique(cmin(:))',0)
    Y(:,ci==c) = repmat(-Ypos(:,-c),[1,sum(ci==c)]);
    l=l+1;
end

% add local noise beta on each time-series
Y = Y + eta*randn(T,N);

% add global signal alpha that correlates globally each time series
Y = Y + mu*repmat(randn(T,1),[1,N]);


% Standardize the time-series
Y = zscore(Y);
% Compute the correlation coefficient
% C is the correlation matrix, P are the P-values of correlation
% coefficients
[C,P] = corrcoef(Y);
