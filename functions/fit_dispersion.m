function [KL,u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion(C,t,u,Cj,Ci,L,p)
%fit_dispersion solves KL (SI) given concentration and time array, interstitial velocity, 
% boundary conditions in x = 0 (Cj), initial concentration, length of the
% core, initial guess parameters

    for i = 1:10
        
        % Cj, Ci, u not fitting, fitting p where Kl = p^2
        C_function = @(p,t)(Ci + (Cj/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p(1))));
        %C_function = @(p,t)(Cj/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p(1)))+(Cj/2)*exp(u*L/(p(1)^2)).*erfc(((L+u.*t).*((t).^(1/2)))./(2*t.*p(1)));
        C_fit = fitnlm(t,C,C_function,p);
        p = C_fit.Coefficients.Estimate;
        
        % % Cj, p, u not fitting, fitting Ci
        % C_function1 = @(Ci,t)(Ci + (Cj(1)/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p)));
        % C_fit = fitnlm(t,C,C_function1,Ci);
        % Ci = C_fit.Coefficients.Estimate;
    
        % % u, p, Ci not fitting, fitting Cj
        % C_function3 = @(Cj,t)(Ci + (Cj(1)/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p)));
        % C_fit = fitnlm(t,C,C_function3,Cj);
        % Cj = C_fit.Coefficients.Estimate;

        % % Cj, p, Ci not fitting, fitting u
        % C_function2 = @(u,t)(Ci + (Cj/2)*erfc(((L-u(1).*t).*((t).^(1/2)))./(2*t.*p)));
        % C_fit = fitnlm(t,C,C_function2,u);
        % u = C_fit.Coefficients.Estimate;
           
        % Cj, Ci, u not fitting, fitting p where Kl = p^2
        C_fit = fitnlm(t,C,C_function,p);
        p = C_fit.Coefficients.Estimate;
     
        KL = p^2;
        u_fit = u;
        Cj_fit = Cj;
        Ci_fit = Ci;
        
    end
end