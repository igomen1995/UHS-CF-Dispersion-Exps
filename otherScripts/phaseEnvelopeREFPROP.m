% 1 - Import phaseBoundaryREFPROP_h2co2 excel each sheet 

xlist = [0 10 25 50 100]; % H2 composition of this spreadsheet

figure
hold on
scatter(phaseBoundaryREFPROPH2CO2S1.T_K, phaseBoundaryREFPROPH2CO2S1.P_MPa, ...
    5,'filled','DisplayName', xlist(1) + "mol % H_2")
scatter(phaseBoundaryREFPROPH2CO2S2.T_K, phaseBoundaryREFPROPH2CO2S2.P_MPa, ...
    5,'filled','DisplayName',xlist(2) + "mol % H_2")
scatter(phaseBoundaryREFPROPH2CO2S3.T_K, phaseBoundaryREFPROPH2CO2S3.P_MPa, ...
    5,'filled','DisplayName',xlist(3) + "mol % H_2")
scatter(phaseBoundaryREFPROPH2CO2S4.T_K, phaseBoundaryREFPROPH2CO2S4.P_MPa, ...
    5,'filled','DisplayName',xlist(4) + "mol % H_2")
scatter(phaseBoundaryREFPROPH2CO2S5.T_K, phaseBoundaryREFPROPH2CO2S5.P_MPa, ...
    5,'filled','DisplayName',xlist(5) + "mol % H_2")
scatter(305.15,10.4,20,'filled','r','DisplayName',"Experimental conditions")
xlabel('Temperature (K)')
ylabel('Pressure (MPa)')
xlim([175,400])
ylim([0,40])
legend()
grid on