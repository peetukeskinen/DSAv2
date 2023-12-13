% Function to project the debt for a given a
function [debt,g,drgdp] = project_debt2v(scenario, a, iir, potgdp, og, epsilon, phi,dcoa,sfa,...
    inflation,initial_debt, spb_initial)

        % THIS FUNCTION CALCULATES PROJECTED DEBT PATH GIVEN INPUTS %
        
        % SELECT SCENARIO TO RUN
        % 1) ADJUSTMENT
        % 2) LOWER SPB
        
        % FUNCTION OUTPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % debt: debt-to-gdp projection
        % g: nominal growth of gdp
        % drgdp: real gdp growth
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % FUNCTION INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % scenario: select scenario
        % a: adjustment per period
        % iir: implicit interest rate
        % potgdp: potential output
        % og: output gap
        % epsilon: elasticity of budget balance
        % phi: fiscal multiplier on impact (2025)
        % dcoa: change in cost of ageing relative to end of adjustment
        % sfa: stock-flow adjustment
        % inflation: price inflation
        % initial_debt: initial level of debt (t-1, 2024)
        % spb_initial: initial level of spb (t, 2025)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
%% Housekeeping        
    years = length(iir); % number of years
    
    % Commission fiscal multiplier based on Carnot and de Castro (2015)
    % Fiscal policy effects output gap during the consolidation 
    % period 2025 - 2028 (see 2nd infobox p. 66 from the report)
    m = [0 phi phi*(5/3) phi*(6/3) phi*(6/3) phi phi*(1/3) zeros(1,8)];
    
    % Initialize arrays
    rgdp = NaN(1, years);
    drgdp = NaN(1, years);
    g = NaN(1, years);
    debt = NaN(1, years);
    
    %set initial values for 2024
    rgdp(1) = (1 + og(1)/100) * potgdp(1); %real gdp level
    debt(1) = initial_debt; %initial debt level in 2024
   
%% Main projection loop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for t = 2:years % start from 1st consolidation year (2025)
        
        % Primary balance calculations 
        if scenario == 1
            % ADJUSTMENT scenario
            if t <= 5 % PB during 4 year adjustment
                pb_t = (t-1)*a + spb_initial + epsilon*(og(t)-m(t)*a);
            else % PB after the adjustment (10 years)
                pb_t = 4*a + spb_initial + epsilon*(og(t)-m(t)*a) + dcoa(t);
            end
            
        elseif scenario == 2
            % LOWER SPB scenario
            if t <= 5 % 4 year adjustment
                pb_t = (t-1)*a + spb_initial + epsilon*(og(t)-m(t)*a);
            elseif t == 6 % 0.25% lower SPB*
                pb_t = 4*a + spb_initial-0.25 + epsilon*(og(t)-m(t)*a) + dcoa(t);
            else % permanently 0.5% lower SPB*
                pb_t = 4*a + spb_initial-0.5 + epsilon*(og(t)-m(t)*a) + dcoa(t);
            end
            
        else
            disp('No deterministic scenario selected.');
            return;
        end
        
        % calculate implied real gdp level based on og, m, a, potgdp
        % og and a are scaled by 0.01 to get the decimal form
        rgdp(t) = (1 + og(t)*0.01 - m(t)*a*0.01) * potgdp(t); % real gdp level
        % real gdp level is affected by adjustment a times the multiplier m
        
        drgdp(t) =  ((rgdp(t) - rgdp(t-1)) / rgdp(t-1)); % real gdp growth
        g(t) = ((rgdp(t) - rgdp(t-1)) / rgdp(t-1)) + inflation(t); % nominal gdp growth
        
        % Debt dynamics (equation 3, p. 57)
        debt(t) = debt(t-1) * (1 + iir(t)) / (1 + g(t)) - pb_t + sfa(t);
    end
end