classdef Battery < handle

    properties (SetAccess = immutable)
        param_A                 % [V]
        param_B                 % [Ah^-1]
        param_K                 % [V]
        voltage_full            % [V]
        voltage_exp             % [V]
        voltage_nom             % [V]
        q_full                  % [Ah]
        q_exp                   % [Ah]
        q_nom                   % [Ah]
        internal_resistance     % [Ohm]
        num_series
        num_parallel
        cc_current              % [A]
    end

    properties(SetAccess = protected)
        param_E0                % [V]
        discharge_capacity      % [Ah]
        voltage                 % [V]
        current                 % [A]
        dod                     % [%] (depth of discharge)
    end
    
    methods (Access = public)

        function obj = Battery(args)
            
            num_series = args.module.series;
            num_parallel = args.module.parallel;
            obj.cc_current = args.module.cc_current;
            obj.num_series = num_series;
            obj.num_parallel = num_parallel;
            obj.voltage_full = args.cell.voltage.full * num_series;
            obj.voltage_exp = args.cell.voltage.exponential * num_series;
            obj.voltage_nom = args.cell.voltage.nominal * num_series;
            obj.q_full = args.cell.capacity.full * num_series * num_parallel;
            obj.q_exp = args.cell.capacity.exponential * num_series * num_parallel;
            obj.q_nom = args.cell.capacity.nominal * num_series * num_parallel;

            obj.param_A = obj.voltage_full - obj.voltage_exp;
            obj.param_B = 3.0/obj.q_exp;
            obj.param_K = (obj.voltage_full - obj.voltage_nom + obj.param_A*(exp(-obj.param_B*obj.q_nom)-1))*(obj.q_full - obj.q_nom)/obj.q_nom;

            % The following line should be modified later
            obj.internal_resistance = args.cell.internal_resistance * num_series;

            % This value should be changed by the argument of the constructor
            obj.discharge_capacity = 0;

            % This value should be calculated from the initial discharge capacity
            obj.voltage = obj.voltage_full;

        end

        function updateBatteryStatus(this, current, delta_time)
            if (this.voltage >= this.voltage_full && current <= 0)
            else
                if (current < this.cc_current)
                    current = this.cc_current;
                end
                this.current = current;
                this.updateDischargeCapacity(current, delta_time);
                this.updateBatteryVoltage(current);
                this.updateDepthOfDischarge();
            end
        end

        function output = getBatteryVoltage(this)
            output = this.voltage;
        end

        function output = getBatteryCurrent(this)
            output = this.current;
        end

        function output = getDepthOfDischarge(this)
            output = this.dod;
        end
    end

    methods (Access = protected)
        function updateDischargeCapacity(this, current, delta_time)
            this.discharge_capacity = this.discharge_capacity + current*delta_time;
        end

        function updateBatteryVoltage(this, current)
            E0 = this.calculateParameterE0(current);
            K = this.param_K;
            Q = this.q_full;
            R = this.internal_resistance;
            A = this.param_A;
            B = this.param_B;
            iT = this.discharge_capacity;
            this.voltage = E0 - K*Q/(Q-iT) - R*current + A*exp(-B*iT);
        end

        function updateDepthOfDischarge(this)
            this.dod = this.discharge_capacity/this.q_full * 100.0;
        end

        function output = calculateParameterE0(this, current)
            output = this.voltage_full + this.param_K + this.internal_resistance*current - this.param_A;
        end
    end

end