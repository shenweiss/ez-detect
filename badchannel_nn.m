function [Y,Xf,Af] = myNeuralNetworkFunction(X,~,~)

% threshold = 0.32

%MYNEURALNETWORKFUNCTION neural network simulation function.
%
% Generated by Neural Network Toolbox function genFunction, 26-Mar-2018 09:54:29.
%
% [Y] = myNeuralNetworkFunction(X,~,~) takes these arguments:
%
%   X = 1xTS cell, 1 inputs over TS timesteps
%   Each X{1,ts} = Qx11 matrix, input #1 at timestep ts.
%
% and returns:
%   Y = 1xTS cell of 1 outputs over TS timesteps.
%   Each Y{1,ts} = Qx1 matrix, output #1 at timestep ts.
%
% where Q is number of samples (or series) and TS is the number of timesteps.

%#ok<*RPMT0>

% ===== NEURAL NETWORK CONSTANTS =====

% Input 1
x1_step1.xoffset = [0.00475862895952849;-3.31478286017484;-3.24031663939268e+15;0.12161437248789;-3.79435082787433;6.74003244116594e-06;-8.34768662408144;9.09588370867631e-06;-5.16852419848239;0.0767431441940806;-4.65919721127571];
x1_step1.gain = [6.69058454532785;0.32336843048967;6.1722363045818e-16;2.29215229629343;0.560571516357662;2.03963011339198;0.21173861720788;2.02683662984744;0.302589117750439;2.17224145717361;0.435076958889332];
x1_step1.ymin = -1;

% Layer 1
b1 = [-1.708121917953760116;1.3472344695114122359;-1.2784511766875230609;0.05011697473590195212;-0.20850098090754676239;-0.94105243986508657628;1.1732556136382465972;0.92585956988727025063;-1.5444374384094421426;1.7681207876205160545];
IW1_1 = [0.77294818688999911149 -0.99838443783034702683 -0.55405401012236732416 0.51062073319432643714 -0.32051758120043621902 -0.35618688113341673285 0.15427322786416294842 -0.22591082357330377617 -0.5734701174694124548 -0.18530018023022348794 -0.074928324990986103216;-1.0726376815935425579 0.29158195080241328112 0.61402775824694255657 0.42763904701306126865 -0.19157291901355297248 0.32955304913762134555 -0.43622549116699987914 -0.51699331281113514169 0.57078014615568228862 -0.38731608133967926344 -0.36513351141001920697;0.73840387493209758141 -0.50889024496029056088 -0.40381237837872258067 -0.92377968799937815181 -0.48590646593993430669 0.013102973517811413937 0.67129618714043604033 -0.15041864683863190311 0.14583875975551580106 -0.38299350602574094848 0.38009878253375245505;-0.0090488069823537204545 0.031692215970386523882 1.0434180981436140812 1.0368398149094602001 -0.25800688044042191516 0.79293198449295831942 0.6397164505042034488 0.9351128630419052179 0.57254283329026334215 0.74209273686397103642 -0.63070440993679710573;0.1453289625835762211 0.12568918793270242307 -0.27924378077644601559 0.028547623752999212732 0.27809011116846199529 -0.82568621255696705852 -0.84705208818023058903 -0.56740174662642239856 -0.81169177174950402076 -0.44306085205802031579 -0.54494162155994663177;-0.69768120468056671335 -1.5823861621577088865 -0.51123241470068381265 -0.56070663827333566687 -0.47841232818913642655 0.69306118147504847116 0.62255728709217106331 -0.73178605149096298543 -0.99188187708561648126 -0.67454248814945982904 -0.82212005176915625704;-0.064390817239826397822 0.36923747043714189031 0.74935223068327128093 -1.3033938284928257012 1.5635375086028819869 0.61878761256857706119 -1.682267733161764367 0.19995333704762682792 0.39346013028277043722 0.3592847550222413866 0.84626443538259599197;0.14758162670313945686 0.27649060786567619674 0.27997233417331740535 -0.6004974921307938418 -0.36587632751322279878 0.36498779869603709125 -0.2771942317055771654 0.83698124993094302759 -0.7391360952114682803 -0.024958104714907284466 -1.1059569614135611459;-0.860112338340774496 -1.024868113563786487 0.40626748351291647188 -0.20074288873803330935 -0.093325301797296394968 -0.43577260127561728842 -0.51218127675017122158 0.200982045081178895 0.31574130114674991976 -0.67420957904619327472 -0.093349136407352484301;0.29468138191166326489 0.56424973335816774878 0.65806843280076698921 -1.10812698892579653 0.3401102256760439313 -0.61217696431739310192 -0.75695536772524485425 -1.1708886407459913048 1.137272426953297666 0.30336054284787317137 -0.38635945701047136325];

% Layer 2
b2 = 0.47699328658145190296;
LW2_1 = [0.89197887574492906726 0.57552417729203375618 -1.3328716209018804939 -1.7048340874348011376 -0.28348599052381595609 1.9038252776508139963 -2.0414518206251512922 0.23829020709378465059 0.25647250890173001192 -2.1624873569999940592];

% ===== SIMULATION ========

% Format Input Arguments
isCellX = iscell(X);
if ~isCellX
    X = {X};
end

% Dimensions
TS = size(X,2); % timesteps
if ~isempty(X)
    Q = size(X{1},1); % samples/series
else
    Q = 0;
end

% Allocate Outputs
Y = cell(1,TS);

% Time loop
for ts=1:TS
    
    % Input 1
    X{1,ts} = X{1,ts}';
    Xp1 = mapminmax_apply(X{1,ts},x1_step1);
    
    % Layer 1
    a1 = tansig_apply(repmat(b1,1,Q) + IW1_1*Xp1);
    
    % Layer 2
    a2 = logsig_apply(repmat(b2,1,Q) + LW2_1*a1);
    
    % Output 1
    Y{1,ts} = a2;
    Y{1,ts} = Y{1,ts}';
end

% Final Delay States
Xf = cell(1,0);
Af = cell(2,0);

% Format Output Arguments
if ~isCellX
    Y = cell2mat(Y);
end
end

% ===== MODULE FUNCTIONS ========

% Map Minimum and Maximum Input Processing Function
function y = mapminmax_apply(x,settings)
y = bsxfun(@minus,x,settings.xoffset);
y = bsxfun(@times,y,settings.gain);
y = bsxfun(@plus,y,settings.ymin);
end

% Sigmoid Positive Transfer Function
function a = logsig_apply(n,~)
a = 1 ./ (1 + exp(-n));
end

% Sigmoid Symmetric Transfer Function
function a = tansig_apply(n,~)
a = 2 ./ (1 + exp(-2*n)) - 1;
end
