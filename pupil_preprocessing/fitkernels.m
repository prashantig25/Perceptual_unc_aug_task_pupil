% This code defines a function called single_pupil_IRF that takes in two arguments: params and x. 
% The function calculates the impulse response function (IRF) of the human pupil using a single-component model.
% The params argument is a dictionary containing the parameters of the model:
% s1: the amplitude of the IRF
% n1: the exponent of the IRF
% tmax1: the time constant of the IRF
% The x argument is the time vector at which the IRF is evaluated.
% The function first extracts the values of s1, n1, and tmax1 from the params dictionary. 
% Then, it calculates the IRF using the following equation:

classdef fitkernels
    properties
        params
        x % time window
%         s1
%         s2
%         n1
%         n2
%         tmax1
%         tmax2
        kernel1
        kernel2
        data
        ls1
        ls2
    end
    methods
        function obj = fitkernels
            addparam(obj.params,'s1',-1,-inf,-1e-25)
            addparam(obj.params,'s2',1,-inf,-1e-25)
            addparam(obj.params,'n1',10,9,11)
            addparam(obj.params,'n2',10,8,12)
            addparam(obj.params,'tmax1',0.9,0.5,1.5)
            addparam(obj.params,'tmax2',2.5,1.5,4)
        end
        function single_pupil_IRF(obj)
            s1 = obj.params.s1.Value;
            n1 = obj.params.n1.value;
            obj.kernel1 = s1 * ((obj.x.^n1) * (e.^((-n1*obj.x)/tmax1)));
        end
        function single_pupil_IRF_ls(obj)
            obj.single_pupil_IRF();
            obj.ls1 = obj.kernel1 - obj.data;
        end
        function double_pupil_IRF(obj)
            s1 = obj.params.s1.Value;
            n1 = obj.params.n1.value;
            s2 = obj.params.s2.value;
            n2 = obj.params.n2.value;
            tmax1 = obj.params.tmax1.value;
            tmax2 = obj.params.tmax2.value;
            obj.kernel2 = s1 * ((obj.x.^n1) * (e.^((-n1*obj.x)/tmax1))) + s2 * ((obj.x.^n2) * (e.^((-n2*obj.x)/tmax2)));
        end
        function double_pupil_IRF_ls(obj)
            obj.double_pupil_IRF();
            obj.ls2 = obj.kernel2 - obj.data;
        end
    end
end