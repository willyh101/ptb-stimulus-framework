classdef StimulusManager < handle
	%{
	The stimulus manager is the main interface for dealing with all the subclasses. Upon instantiating the StimulusManager, each other class for the necessary use of the framework is also instantiated. Then, the StimulusManager is the only class that needs to be dealt with, and will correctly pass arguments to the proper object for stimulus presentation

	Written 14Feb2020 KS
	Updated
	%}

	properties
		% Pointers to each of the required "subojects"
		renderer
		logger
		triggerer
		timer

		current_repeat = 1
		current_presentation = 0 % I know... I don't like it either, but it works
	end

	methods
		function obj = StimulusManager()
			% Instantiate all the objects
			obj.logger = StimDataLogger();
			obj.timer = StimulusTimer();
			obj.triggerer = MicroscopeTriggerer();
			obj.renderer = StimulusRenderer();
		end

		function setScreenID(obj, id)
			obj.renderer.setScreenID(id);
		end

		function initialize(obj)
			% Not ideal, because i want to loop through the properties, but this will work.. for now
			obj.logger.initialize();
			obj.triggerer.initialize(obj.timer.getStimulusDuration()); % Pass into the triggerer
			obj.timer.initialize();
			obj.renderer.initialize(obj);
		end

		function start(obj)
			obj.renderer.start();
			obj.logger.start();
			obj.triggerer.start();
			obj.timer.start();
		end

		function finish(obj)
			obj.renderer.finish();			
			obj.timer.finish();
			obj.triggerer.finish();
			obj.logger.finish();
		end

		function setTrigger(obj, enable)
			obj.triggerer.setTrigger(enable);
		end

		function present(obj, stim_type, varargin)
	    	obj.increment(); % Increments the manager's counters

	    	obj.report('Pre blank'); % spaces are for alignment
	        obj.renderer.drawBlank(obj.timer.calculatePreClose(obj.current_presentation, obj.current_repeat)); % everything else is held in the object
	        
	        obj.report('Stimulus');
	        obj.instructRenderer(stim_type, obj.timer.calculateStimClose(obj.current_presentation, obj.current_repeat), varargin{:});

	        obj.report('Post blank')
	        obj.renderer.drawBlank(obj.timer.calculatePostClose(obj.current_presentation, obj.current_repeat));
	    end
	end

	methods (Access = private)
		function instructRenderer(obj, stim_type, t_close, varargin)
			switch stim_type
			case 'grating'
				obj.renderer.drawDriftingGrating(t_close, varargin{:});
			case 'image'
				obj.renderer.drawImage(t_close, varargin{:});
			case 'movie'
				obj.renderer.drawMovie(t_close, varargin{:});
			case 'blank'
				obj.renderer.drawBlank(t_close, varargin{:});
			end
		end

		function increment(obj)
			if obj.current_presentation < obj.timer.n_presentations
	    		obj.current_presentation = obj.current_presentation + 1; % increment
	    	else
	    		obj.current_presentation = 1;
	    		obj.current_repeat = obj.current_repeat + 1; % increment repeats when we hit presentations
	    	end
	    end

	    function report(obj, epoch)
	    	if strcmp(epoch, 'Pre blank')
	    		fprintf('Presentation #%02d/%02d | Repeat #%02d/%02d | %s (%0.2f)\n', obj.current_presentation, obj.timer.n_presentations, obj.current_repeat, obj.timer.n_repeats, pad([epoch ' on'], 13, 'right'), obj.timer.get());
	    	else
	    		fprintf('                    |               | %s (%0.2f)\n', pad([epoch ' on'], 13, 'right'), obj.timer.get());
	    	end
	    end
	end
end