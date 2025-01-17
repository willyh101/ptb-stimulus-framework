% Test triggered from daq, randomly presenting stimuli each trial. Sends flip
% on/off info to daq.
% Also attempts to send a binary pulse output that indicates the stim ID.


% just get a renderer going?
orientation_list = [0:30:330];
sz_list = round(linspace(10, 1000, length(orientation_list)));
for ori = 1:numel(orientation_list)
    stimulus(ori) = DriftingGrating(orientation_list(ori), [], [], [], [], sz_list(ori));
end

renderer = StimulusRenderer(stimulus); % can be an array of renderables?
renderer.setScreenID(1); % direct call to psychtoolbox
renderer.initialize(); % pass a timer, but do we need it? probably...

renderer.start();

% NIDAQ OUTPUT
dq = daq.createSession('ni');

% in use
% note changes between here and test_franken_trigger_send_pulse
addDigitalChannel(dq,'Dev2', 'Port0/Line1', 'OutputOnly'); %stim on indicator to master
addDigitalChannel(dq,'Dev2', 'Port0/Line4', 'OutputOnly'); %stim on indicator to SI
addDigitalChannel(dq,'Dev2', 'Port0/Line3', 'OutputOnly'); %pulsing info to master
addDigitalChannel(dq,'Dev2', 'Port0/Line0', 'OutputOnly'); % clock output for bin repr


%NIDAQ INPUT
s0 = daq.createSession('ni');
[~,~] = s0.addAnalogInputChannel('Dev2',2,'Voltage');
addTriggerConnection(s0,'external','Dev2/PFI1','StartTrigger');
s0.ExternalTriggerTimeout = 20;
s0.NumberOfScans = 2;

mxNumTrials = 10;

% for simple case of random stimulus presentation
% or do a while loop or whatever
clear stimLog
for i=1:mxNumTrials
    
    % randomly choose a stimulus
    idx = randi(numel(stimulus));
    
    try
        disp('awaiting trigger!')
        % block until recv trig from daq
        s0.startForeground();
    catch
        disp('daq start trigger timed out...')
        % cleanup and save what's been done
        return
    end
    
    outputSingleScan(dq,[1 1 0 0 0]) % set stim indicators up
    renderer.drawStimulus(idx, 1)
    outputSingleScan(dq,[0 0 0 0 0]) % set stim indicators down
    stimLog(i) = idx;
    
    % send stim ID back to daq
    blank = zeros(1, size(dq.Channels,2));
    
    on = blank;
    on(3) = 1; % id pulse
    on(4) = 1; % clock
    
    off = blank;
    off(3) = 0; % id pulse
    off(4) = 1; % clock
    
    binaryVec = decimalToBinaryVector(idx, 12);
    
    for pulseI = 1:12 % 12 bits should be way plenty
        valToSend = binaryVec(pulseI);
        if valToSend == 0
            outputSingleScan(dq, off);
        else
            outputSingleScan(dq, on);
        end
        pause(.01)
        outputSingleScan(dq, blank);
    end
    
end

renderer.finish();
    